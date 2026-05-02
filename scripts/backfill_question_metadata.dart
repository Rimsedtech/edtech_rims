// ignore_for_file: avoid_print

/// Backfill script: Stamp denormalised metadata onto Admin-Panel questions.
///
/// HOW IT WORKS
/// ─────────────
/// The Obsidian → Firestore upload pipeline already writes `subject`,
/// `difficulty`, `group`, and `random` directly onto every question document
/// (see upload_to_firestore.dart). The Admin Panel does NOT — it only stores
/// those fields on the parent *exam* document.
///
/// This script:
///   1. Iterates every exam document in the `exams` collection.
///   2. For each exam, reads all question documents in its `questions`
///      sub-collection.
///   3. If a question is missing ANY of the four denormalised fields, it writes
///      them (reading from the parent exam) using a Firestore `update`.
///   4. Uses batched writes (max 500 ops / batch) for efficiency.
///
/// USAGE
/// ──────
/// Run from the `app/` directory:
///
///   dart run scripts/backfill_question_metadata.dart
///
/// PREREQUISITES
/// ──────────────
///   • `service-account.json` must exist in `app/`
///   • `dart pub get` must have been run
///
/// DRY-RUN MODE
/// ─────────────
/// Set the `DRY_RUN` constant below to `true` to preview what would be changed
/// without committing any writes to Firestore.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart' as admin;
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

// ── Config ────────────────────────────────────────────────────────────────────

/// Set to true to log what would change without writing to Firestore.
const bool DRY_RUN = false;

/// Maximum operations in a single Firestore batch.
const int _batchSize = 400;

// ── Entry point ───────────────────────────────────────────────────────────────

void main() async {
  const String serviceAccountPath = 'service-account.json';

  final serviceAccountFile = File(serviceAccountPath);
  if (!serviceAccountFile.existsSync()) {
    print('❌ ERROR: service-account.json not found in the app/ directory.');
    exit(1);
  }

  print('🔗 Initializing Firebase Admin SDK...');

  final Map<String, dynamic> serviceAccountJson =
      jsonDecode(serviceAccountFile.readAsStringSync()) as Map<String, dynamic>;
  final String projectId = serviceAccountJson['project_id'] as String;

  final app = admin.FirebaseApp.initializeApp(
    options: admin.AppOptions(
      credential: admin.Credential.fromServiceAccount(serviceAccountFile),
      projectId: projectId,
    ),
  );

  final firestore = app.firestore();
  final rng = Random();

  if (DRY_RUN) {
    print('🟡 DRY-RUN MODE – no writes will be committed.\n');
  }

  // ── Step 1: Fetch all exam documents ────────────────────────────────────────
  print('📚 Fetching all exam documents...');
  final examsSnap = await firestore.collection('exams').get();
  final examDocs = examsSnap.docs;
  print('   Found ${examDocs.length} exams.\n');

  int totalInspected = 0;
  int totalPatched = 0;
  int totalSkipped = 0;
  int batchOpCount = 0;
  var batch = firestore.batch();

  final Set<String> allSubjects = {};
  final Set<String> allDifficultyTiers = {};
  final Set<String> allGroups = {};
  final Map<String, Set<String>> subjectGroupsRaw = {};

  Future<void> commitBatch() async {
    if (batchOpCount == 0) return;
    if (!DRY_RUN) {
      await batch.commit();
      print('   ✅ Committed batch of $batchOpCount write(s).');
    }
    batchOpCount = 0;
    batch = firestore.batch();
  }

  // ── Step 2: Iterate each exam ────────────────────────────────────────────────
  for (final examDoc in examDocs) {
    final examData = examDoc.data();
    final examId = examDoc.id;

    // Read the exam-level metadata we need to propagate
    final String subject = _stringField(examData, 'subject');
    final String difficulty = _stringField(examData, 'difficultyTier');
    final String group = _stringField(examData, 'group');

    if (subject.isEmpty && difficulty.isEmpty && group.isEmpty) {
      print(
        '⚠️  Exam $examId has no metadata (subject/difficulty/group). '
        'Skipping its questions.',
      );
      continue;
    }

    if (subject.isNotEmpty) {
      allSubjects.add(subject);
      if (group.isNotEmpty) {
        subjectGroupsRaw.putIfAbsent(subject, () => {}).add(group);
      }
    }
    if (difficulty.isNotEmpty) allDifficultyTiers.add(difficulty);
    if (group.isNotEmpty) allGroups.add(group);

    // ── Step 3: Fetch all questions for this exam ──────────────────────────────
    final questionsSnap = await firestore
        .collection('exams/$examId/questions')
        .get();
    final questionDocs = questionsSnap.docs;

    for (final qDoc in questionDocs) {
      totalInspected++;
      final qData = qDoc.data();
      final qId = qDoc.id;

      // Collect granular difficulty for metadata config
      final String? qDiff = qData['difficultyTier'] as String?;
      if (qDiff != null && qDiff.isNotEmpty) {
        allDifficultyTiers.add(qDiff);
      }

      // Check which fields are missing
      final bool missingSubject = !qData.containsKey('subject');
      final bool missingDifficultyTier = !qData.containsKey('difficultyTier');
      final bool missingGroup = !qData.containsKey('group');
      final bool missingRandom = !qData.containsKey('random');

      if (!missingSubject &&
          !missingDifficultyTier &&
          !missingGroup &&
          !missingRandom) {
        totalSkipped++;
        continue; // Already has all fields – nothing to do
      }

      final Map<String, dynamic> updates = {};
      if (missingSubject) updates['subject'] = subject;
      if (missingDifficultyTier) updates['difficultyTier'] = difficulty;
      if (missingGroup) updates['group'] = group;
      if (missingRandom) updates['random'] = rng.nextDouble();

      if (DRY_RUN) {
        print(
          '  [DRY-RUN] Would patch exam=$examId question=$qId '
          'with: ${updates.keys.join(', ')}',
        );
      } else {
        batch.update(
          firestore.doc('exams/$examId/questions/$qId'),
          updates.map((key, value) => MapEntry(FieldPath([key]), value)),
        );
        batchOpCount++;

        if (batchOpCount >= _batchSize) {
          await commitBatch();
        }
      }

      totalPatched++;
    }

    print(
      '📝 Exam $examId (${questionDocs.length} questions): '
      'patched $totalPatched so far.',
    );
  }

  // Commit any remaining operations
  await commitBatch();

  // ── Step 4: Write metadata config ────────────────────────────────────────────
  if (!DRY_RUN) {
    print('📝 Writing metadata config to metadata/mock_test_config...');
    try {
      final Map<String, List<String>> subjectGroupsMap = subjectGroupsRaw.map(
        (key, value) => MapEntry(key, value.toList()..sort()),
      );

      await firestore.doc('metadata/mock_test_config').set({
        'subjects': allSubjects.toList()..sort(),
        'groups': allGroups.toList()..sort(),
        'subjectGroups': subjectGroupsMap,
        'difficultyTiers': ['easy', 'medium', 'hard', 'ultra_hard'],
        'lastUpdated': DateTime.now().toIso8601String(),
      });
      print('   ✅ Metadata config written.');
    } catch (e) {
      print('   ❌ Error writing metadata config: $e');
    }
  } else {
    print('  [DRY-RUN] Would write metadata config with:');
    print('    Subjects: $allSubjects');
    print('    Groups: $allGroups');
    print('    SubjectGroups: $subjectGroupsRaw');
    print(
      '    Difficulty Tiers: [\'easy\', \'medium\', \'hard\', \'ultra_hard\']',
    );
  }

  // ── Summary ──────────────────────────────────────────────────────────────────
  print('\n══════════════════════════════════════════');
  print('  BACKFILL COMPLETE');
  print('  Exams scanned   : ${examDocs.length}');
  print('  Questions seen  : $totalInspected');
  print('  Questions patched: $totalPatched');
  print('  Questions skipped (already OK): $totalSkipped');
  if (DRY_RUN) print('  ⚠️  DRY-RUN – no data was written.');
  print('══════════════════════════════════════════\n');

  exit(0);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Safely read a string value from a Firestore document field map.
/// Returns an empty string if the field is absent or not a string.
String _stringField(Map<String, dynamic> fields, String key) {
  final value = fields[key];
  if (value == null) return '';
  return value.toString();
}

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart' as admin;
import 'package:google_cloud_storage/google_cloud_storage.dart' as gcs;
import 'package:path/path.dart' as p;

void main() async {
  // Paths are relative to the 'app' directory
  const String serviceAccountPath = 'service-account.json';
  const String seedPath = 'database_seed.json';

  final serviceAccountFile = File(serviceAccountPath);
  final seedFile = File(seedPath);

  if (!serviceAccountFile.existsSync()) {
    print('❌ ERROR: service-account.json not found in /app directory.');
    exit(1);
  }

  if (!seedFile.existsSync()) {
    print('❌ ERROR: $seedPath not found! Run the obsidian_parser.dart first.');
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

  // Initialize Cloud Storage
  // We expect GOOGLE_APPLICATION_CREDENTIALS to be set in the shell environment
  final storage = gcs.Storage();
  final String bucketName =
      serviceAccountJson['storage_bucket'] ?? '$projectId.firebasestorage.app';

  print('🪣 Using Storage Bucket: $bucketName');

  try {
    final Map<String, dynamic> seedData =
        jsonDecode(seedFile.readAsStringSync()) as Map<String, dynamic>;
    final List<dynamic> exams =
        (seedData['exams'] as List<dynamic>?) ?? <dynamic>[];

    if (exams.isEmpty) {
      print('⚠️ No exams found in $seedPath.');
      return;
    }

    print(
      '🚀 Starting optimized upload of ${exams.length} exams to project: $projectId...',
    );

    final Set<String> uniqueSubjects = {};
    final Set<String> uniqueGroups = {};
    final Map<String, Set<String>> subjectGroupsMap = {};

    for (int i = 0; i < exams.length; i++) {
      final Map<String, dynamic> examData = Map<String, dynamic>.from(
        exams[i] as Map<dynamic, dynamic>,
      );
      final String title = (examData['title'] as String?) ?? 'Untitled Exam';

      print('\n[${i + 1}/${exams.length}] Processing: $title');

      // 1. Validation
      final List<String> requiredFields = [
        'title',
        'subject',
        'group',
        'durationMinutes',
        'questions',
      ];
      final List<String> missingFields = requiredFields
          .where((String f) => !examData.containsKey(f))
          .toList();

      if (missingFields.isNotEmpty) {
        print('   ⚠️ Skipping exam due to missing fields: $missingFields');
        continue;
      }

      final List<dynamic> questions = List<dynamic>.from(
        examData['questions'] as Iterable<dynamic>,
      );

      // 2. Prepare Exam Document
      final Map<String, dynamic> examDoc = Map<String, dynamic>.from(examData)
        ..remove('questions');

      // Ensure numeric types
      examDoc['durationMinutes'] = (examDoc['durationMinutes'] as num).toInt();
      examDoc['xpReward'] = (examDoc['xpReward'] as num?)?.toInt() ?? 100;
      examDoc['questionCount'] = (examDoc['questionCount'] as num?)?.toInt() ?? questions.length;
      examDoc['status'] = (examDoc['status'] as String?) ?? 'published';

      // Convert timestamps to DateTime (Firestore SDK converts to Timestamps)
      examDoc['createdAt'] = _parseDate(examDoc['createdAt']);
      examDoc['updatedAt'] = DateTime.now().toUtc();

      // 3. Check for existing exam (Upsert) to prevent duplicates
      final allExamsSnapshot = await firestore.collection('exams').get();
      final duplicateDocs = allExamsSnapshot.docs.where((d) {
        final data = d.data();
        return data['title'] == title;
      }).toList();

      final batch = firestore.batch();
      dynamic examRef;

      if (duplicateDocs.isNotEmpty) {
        examRef = firestore.collection('exams').doc(duplicateDocs.first.id);
        print('   ♻️  Found existing exam. Updating ${duplicateDocs.first.id}...');
        
        // Delete old questions to replace them
        final oldQuestions = await examRef.collection('questions').get();
        for (final doc in oldQuestions.docs) {
          batch.delete(examRef.collection('questions').doc(doc.id));
        }
        
        // Cleanup any duplicates
        for (int j = 1; j < duplicateDocs.length; j++) {
           final duplicateRef = firestore.collection('exams').doc(duplicateDocs[j].id);
           final dupQuestions = await duplicateRef.collection('questions').get();
           for (final qDoc in dupQuestions.docs) {
             batch.delete(duplicateRef.collection('questions').doc(qDoc.id));
           }
           batch.delete(duplicateRef);
           print('   🗑️  Deleted duplicate exam: ${duplicateDocs[j].id}');
        }
      } else {
        examRef = firestore.collection('exams').doc();
      }

      batch.set(examRef, examDoc);

      // Update unique lists
      final subj = (examDoc['subject'] as String?) ?? 'General';
      final grp = (examDoc['group'] as String?) ?? '';
      uniqueSubjects.add(subj);
      if (grp.isNotEmpty) {
        uniqueGroups.add(grp);
        subjectGroupsMap.putIfAbsent(subj, () => {}).add(grp);
      }

      // Add questions to batch
      for (final dynamic q in questions) {
        final Map<String, dynamic> qData = Map<String, dynamic>.from(
          q as Map<dynamic, dynamic>,
        );


        qData['points'] = (qData['points'] as num?)?.toInt() ?? 1;
        qData['order'] = (qData['order'] as num?)?.toInt() ?? 0;
        qData['xpReward'] = (qData['xpReward'] as num?)?.toInt() ?? qData['points'];

        // Inject parent metadata for global random queries
        qData['subject'] = examDoc['subject'];
        qData['group'] = examDoc['group'];

        // Remove difficultyTier if present (no longer used in queries)
        qData.remove('difficultyTier');

        // Add random seed for selection
        qData['random'] = Random().nextDouble();

        // 4. Handle Diagram Upload to Storage
        if (qData.containsKey('diagramUrl') && qData['diagramUrl'] != null) {
          final String localPath = qData['diagramUrl'] as String;
          if (localPath.startsWith('/') && File(localPath).existsSync()) {
            final File file = File(localPath);
            final String fileName = p.basename(localPath);
            final String destination = 'exams/diagrams/$fileName';

            print('   🖼️  Uploading diagram: $fileName...');
            try {
              // Upload to GCS
              // We make it public for simplicity in this demo environment
              // In production, you might want to use signed URLs or Firebase Storage security rules
              await storage.uploadObject(
                bucketName,
                destination,
                file.readAsBytesSync(),
                metadata: gcs.ObjectMetadata(
                  contentType: _getContentType(fileName),
                ),
              );

              // Construct a public URL
              // Format: https://storage.googleapis.com/[BUCKET]/[PATH]
              final String publicUrl =
                  'https://storage.googleapis.com/$bucketName/$destination';
              qData['diagramUrl'] = publicUrl;
              print('   🔗 Uploaded to: $publicUrl');
            } catch (e) {
              print('   ❌ Failed to upload diagram $fileName: $e');
              // Keep the local path if it fails, though it won't work in the app
            }
          }
        }

        final qRef = examRef.collection('questions').doc();
        batch.set(qRef, qData);
      }

      print(
        '   📤 Committing batch (1 exam + ${questions.length} questions)...',
      );
      await batch.commit();
      print('   ✅ Success! Document ID: ${examRef.id}');
    }

    print('\n🔄 Updating central mock_test_config...');
    final configRef = firestore.doc('metadata/mock_test_config');
    try {
      final configSnapshot = await configRef.get();
      final existingData = configSnapshot.data();
      if (existingData != null) {
        uniqueSubjects.addAll(
          List<String>.from((existingData['subjects'] as List<dynamic>?) ?? []),
        );
        uniqueGroups.addAll(
          List<String>.from((existingData['groups'] as List<dynamic>?) ?? []),
        );
        
        final existingSubjectGroups = existingData['subjectGroups'] as Map<String, dynamic>? ?? {};
        existingSubjectGroups.forEach((k, v) {
          subjectGroupsMap.putIfAbsent(k, () => {}).addAll(
            List<String>.from(v as List<dynamic>).where((g) => g.isNotEmpty),
          );
        });
      }
    } catch (e) {
      print('   ℹ️ Creating new mock_test_metadata document.');
    }

    final Map<String, List<String>> finalSubjectGroups = {};
    subjectGroupsMap.forEach((k, v) {
      finalSubjectGroups[k] = v.toList()..sort();
    });

    await configRef.set({
      'subjects': uniqueSubjects.toList()..sort(),
      'groups': uniqueGroups.toList()..sort(),
      'subjectGroups': finalSubjectGroups,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
    print('✅ Metadata updated successfully.');

    print('\n==================================================');
    print('🎉 ALL TASKS COMPLETED SUCCESSFULLY');
    print('==================================================');
  } catch (e, stack) {
    print('\n❌ FATAL ERROR: $e');
    print(stack);
    exit(1);
  } finally {
    exit(0);
  }
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now().toUtc();
  try {
    if (value is String) return DateTime.parse(value).toUtc();
  } catch (_) {
    // Fall through to default
  }
  return DateTime.now().toUtc();
}

String _getContentType(String fileName) {
  final ext = p.extension(fileName).toLowerCase();
  switch (ext) {
    case '.png':
      return 'image/png';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.gif':
      return 'image/gif';
    case '.webp':
      return 'image/webp';
    case '.svg':
      return 'image/svg+xml';
    default:
      return 'application/octet-stream';
  }
}

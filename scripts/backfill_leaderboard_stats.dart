// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart' as admin;
import 'package:google_cloud_firestore/google_cloud_firestore.dart';

/// Backfill script: Recalculate and update user leaderboard stats.
///
/// This script:
///   1. Iterates every user document.
///   2. For each user, fetches all completed attempts.
///   3. For each attempt, calculates 'correctCount' by comparing answers with exam questions.
///   4. Updates the user's 'totalCorrectAnswers', 'totalExamsTaken', and 'lastExamCompletedAt'.
///
/// USAGE:
///   dart run scripts/backfill_leaderboard_stats.dart

const bool DRY_RUN = false;

void main() async {
  const String serviceAccountPath = 'service-account.json';
  final serviceAccountFile = File(serviceAccountPath);

  if (!serviceAccountFile.existsSync()) {
    print('❌ ERROR: service-account.json not found.');
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

  print('📁 Fetching all users...');
  final usersSnap = await firestore.collection('users').get();
  print('   Found ${usersSnap.docs.length} users.');

  print('📁 Fetching all attempts...');
  final allAttemptsSnap = await firestore.collection('attempts').get();
  final allAttempts = allAttemptsSnap.docs;
  print('   Found ${allAttempts.length} total attempts.\n');

  // Cache for exam questions: examId -> { questionId -> correctAnswer }
  final Map<String, Map<String, String>> examCache = {};

  int usersProcessed = 0;

  for (final userDoc in usersSnap.docs) {
    final String userId = userDoc.id;
    final userData = userDoc.data();
    if (userData == null) continue;
    final String displayName =
        (userData['displayName'] as String?) ?? 'Unknown';

    print('🧐 Processing user: $displayName ($userId)');

    // Filter attempts for this user
    final userAttempts = allAttempts.where((doc) {
      final data = doc.data();
      return data != null &&
          data['userId'] == userId &&
          data['status'] == 'completed';
    }).toList();

    print('   - Found ${userAttempts.length} completed attempts.');

    int totalCorrectAnswers = 0;
    int totalExamsTaken = userAttempts.length;
    DateTime? lastExamCompletedAt;

    for (final attemptDoc in userAttempts) {
      final attemptData = attemptDoc.data();
      if (attemptData == null) continue;

      final String examId = attemptData['examId'] as String;
      final Map<String, dynamic> answers = Map<String, dynamic>.from(
        attemptData['answers'] as Map? ?? {},
      );
      final Timestamp? completedAt = attemptData['completedAt'] as Timestamp?;

      if (completedAt != null) {
        final date = completedAt.toDate();
        if (lastExamCompletedAt == null || date.isAfter(lastExamCompletedAt!)) {
          lastExamCompletedAt = date;
        }
      }

      // If correctCount is already present, use it
      if (attemptData.containsKey('correctCount')) {
        totalCorrectAnswers += (attemptData['correctCount'] as num).toInt();
        continue;
      }

      // Otherwise, calculate it
      if (!examCache.containsKey(examId)) {
        print('     📥 Fetching questions for exam: $examId');
        final questionsSnap = await firestore
            .collection('exams/$examId/questions')
            .get();
        final Map<String, String> questionMap = {};
        for (final qDoc in questionsSnap.docs) {
          final qData = qDoc.data();
          questionMap[qDoc.id] = (qData['correctAnswer'] as String?) ?? '';
        }
        examCache[examId] = questionMap;
      }

      final correctAnswersMap = examCache[examId]!;
      int attemptCorrectCount = 0;
      answers.forEach((qId, answer) {
        if (correctAnswersMap.containsKey(qId) &&
            correctAnswersMap[qId] == answer) {
          attemptCorrectCount++;
        }
      });

      totalCorrectAnswers += attemptCorrectCount;

      // Optional: Update the attempt doc with the calculated correctCount
      if (!DRY_RUN) {
        await firestore.doc('attempts/${attemptDoc.id}').update({
          'correctCount': attemptCorrectCount,
        });
      }
    }

    print('   - Stats: Correct=$totalCorrectAnswers, Exams=$totalExamsTaken');

    if (!DRY_RUN) {
      await firestore.doc('users/$userId').update({
        'totalCorrectAnswers': totalCorrectAnswers,
        'totalExamsTaken': totalExamsTaken,
        'lastExamCompletedAt': lastExamCompletedAt != null
            ? Timestamp.fromDate(lastExamCompletedAt)
            : null,
      });
      print('   ✅ Updated user document.');
    } else {
      print('   [DRY-RUN] Would update user document.');
    }

    usersProcessed++;
  }

  print('\n══════════════════════════════════════════');
  print('  BACKFILL COMPLETE');
  print('  Users processed: $usersProcessed');
  if (DRY_RUN) print('  ⚠️  DRY-RUN – no data was written.');
  print('══════════════════════════════════════════\n');

  exit(0);
}

import 'package:equatable/equatable.dart';

/// Represents a user's attempt at taking an exam.
///
/// Maps to the `attempts/{attemptId}` Firestore document.
class AttemptModel extends Equatable {
  final String id;
  final String userId;
  final String examId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int score;
  final int correctCount;
  final int totalPoints;
  final int xpEarned;
  final AttemptStatus status;
  final Map<String, dynamic> answers;

  const AttemptModel({
    required this.id,
    required this.userId,
    required this.examId,
    required this.startedAt,
    this.completedAt,
    required this.score,
    this.correctCount = 0,
    required this.totalPoints,
    required this.xpEarned,
    required this.status,
    required this.answers,
  });

  /// Score as a percentage (0-100).
  double get scorePercentage =>
      totalPoints > 0 ? (score / totalPoints) * 100 : 0;

  /// Duration of the attempt.
  Duration? get duration => completedAt?.difference(startedAt);

  AttemptModel copyWith({
    String? id,
    String? userId,
    String? examId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? score,
    int? correctCount,
    int? totalPoints,
    int? xpEarned,
    AttemptStatus? status,
    Map<String, dynamic>? answers,
  }) {
    return AttemptModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      examId: examId ?? this.examId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
      totalPoints: totalPoints ?? this.totalPoints,
      xpEarned: xpEarned ?? this.xpEarned,
      status: status ?? this.status,
      answers: answers ?? this.answers,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    examId,
    startedAt,
    completedAt,
    score,
    correctCount,
    totalPoints,
    xpEarned,
    status,
    answers,
  ];
}

/// Attempt lifecycle status.
enum AttemptStatus {
  inProgress,
  completed,
  abandoned;

  String get firestoreValue {
    return switch (this) {
      AttemptStatus.inProgress => 'in_progress',
      AttemptStatus.completed => 'completed',
      AttemptStatus.abandoned => 'abandoned',
    };
  }

  static AttemptStatus fromString(String value) {
    return AttemptStatus.values.firstWhere(
      (AttemptStatus s) => s.firestoreValue == value,
      orElse: () => AttemptStatus.inProgress,
    );
  }
}

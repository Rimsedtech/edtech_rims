import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a single question within an exam.
///
/// Maps to the `exams/{examId}/questions/{questionId}` sub-collection.
class QuestionModel extends Equatable {
  final String id;
  final String questionText;
  final QuestionType questionType;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final int points;
  final int order;
  /// XP awarded when this question is answered correctly.
  /// Defaults to [points] if not explicitly set.
  final int xpReward;
  final String? diagramUrl;

  const QuestionModel({
    required this.id,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.points,
    required this.order,
    int? xpReward,
    this.diagramUrl,
  }) : xpReward = xpReward ?? points;

  /// Creates a [QuestionModel] from a JSON map.
  ///
  /// Compatible with both the Obsidian parser output (`database_seed.json`)
  /// and the Firestore document data format.
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final points = (json['points'] as num?)?.toInt() ?? 1;
    return QuestionModel(
      id: json['id'] as String? ?? '',
      questionText: json['questionText'] as String? ?? '',
      questionType: QuestionType.fromString(
        json['questionType'] as String? ?? 'mcq',
      ),
      options: List<String>.from(json['options'] as List<dynamic>? ?? []),
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      points: points,
      order: (json['order'] as num?)?.toInt() ?? 0,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? points,
      diagramUrl: json['diagramUrl'] as String?,
    );
  }

  /// Creates a [QuestionModel] from a Firestore document snapshot.
  factory QuestionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return QuestionModel.fromJson({...data, 'id': doc.id});
  }

  /// Serializes this question to a JSON-compatible map.
  ///
  /// Uses Firestore field names so the output can be written
  /// directly to `exams/{examId}/questions/{qId}`.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'questionType': questionType.firestoreValue,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'points': points,
      'order': order,
      'xpReward': xpReward,
      if (diagramUrl != null) 'diagramUrl': diagramUrl,
    };
  }

  QuestionModel copyWith({
    String? id,
    String? questionText,
    QuestionType? questionType,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    int? points,
    int? order,
    int? xpReward,
    String? diagramUrl,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      points: points ?? this.points,
      order: order ?? this.order,
      xpReward: xpReward ?? this.xpReward,
      diagramUrl: diagramUrl ?? this.diagramUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    questionText,
    questionType,
    options,
    correctAnswer,
    explanation,
    points,
    order,
    xpReward,
    diagramUrl,
  ];
}

/// Question type matching Firestore field.
enum QuestionType {
  mcq,
  trueFalse,
  shortAnswer;

  String get firestoreValue {
    return switch (this) {
      QuestionType.mcq => 'mcq',
      QuestionType.trueFalse => 'true_false',
      QuestionType.shortAnswer => 'short_answer',
    };
  }

  String get displayName {
    return switch (this) {
      QuestionType.mcq => 'MULTIPLE CHOICE',
      QuestionType.trueFalse => 'TRUE / FALSE',
      QuestionType.shortAnswer => 'SHORT ANSWER',
    };
  }

  static QuestionType fromString(String value) {
    return QuestionType.values.firstWhere(
      (QuestionType q) => q.firestoreValue == value,
      orElse: () => QuestionType.mcq,
    );
  }
}

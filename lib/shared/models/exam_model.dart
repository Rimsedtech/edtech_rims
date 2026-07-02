import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents an exam/evaluation module.
///
/// Maps to the `exams/{examId}` Firestore document.
class ExamModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String group;
  final int durationMinutes;
  final String createdBy;
  final ExamStatus status;
  final int xpReward;
  final int questionCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExamModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.group,
    required this.durationMinutes,
    required this.createdBy,
    required this.status,
    required this.xpReward,
    required this.questionCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an [ExamModel] from a Firestore document snapshot.
  factory ExamModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ExamModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Exam',
      description: data['description'] as String? ?? '',
      subject: data['subject'] as String? ?? 'General',
      group: data['group'] as String? ?? '',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 60,
      createdBy: data['createdBy'] as String? ?? 'System',
      status: ExamStatus.fromString(data['status'] as String? ?? 'draft'),
      xpReward: (data['xpReward'] as num?)?.toInt() ?? 0,
      questionCount: (data['questionCount'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  /// Serializes the [ExamModel] to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'group': group,
      'durationMinutes': durationMinutes,
      'createdBy': createdBy,
      'status': status.name,
      'xpReward': xpReward,
      'questionCount': questionCount,
    };
  }

  ExamModel copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    String? group,
    int? durationMinutes,
    String? createdBy,
    ExamStatus? status,
    int? xpReward,
    int? questionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      group: group ?? this.group,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      xpReward: xpReward ?? this.xpReward,
      questionCount: questionCount ?? this.questionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    subject,
    group,
    durationMinutes,
    createdBy,
    status,
    xpReward,
    questionCount,
    createdAt,
    updatedAt,
  ];
}

/// Exam publication status.
enum ExamStatus {
  draft,
  published,
  archived;

  static ExamStatus fromString(String value) {
    return ExamStatus.values.firstWhere(
      (ExamStatus s) => s.name == value,
      orElse: () => ExamStatus.draft,
    );
  }
}

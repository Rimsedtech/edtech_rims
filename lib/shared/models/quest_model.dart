import 'package:equatable/equatable.dart';

/// Represents a quest (daily/weekly/achievement challenge).
///
/// Maps to the `quests/{questId}` Firestore document.
class QuestModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final int targetValue;
  final int xpReward;
  final String iconName;
  final bool isActive;

  const QuestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.xpReward,
    required this.iconName,
    required this.isActive,
  });

  QuestModel copyWith({
    String? id,
    String? title,
    String? description,
    QuestType? type,
    int? targetValue,
    int? xpReward,
    String? iconName,
    bool? isActive,
  }) {
    return QuestModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      xpReward: xpReward ?? this.xpReward,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    type,
    targetValue,
    xpReward,
    iconName,
    isActive,
  ];
}

/// Quest type.
enum QuestType {
  daily,
  weekly,
  achievement;

  String get displayName {
    return switch (this) {
      QuestType.daily => 'DAILY OBJECTIVE',
      QuestType.weekly => 'WEEKLY MISSION',
      QuestType.achievement => 'ACHIEVEMENT',
    };
  }

  static QuestType fromString(String value) {
    return QuestType.values.firstWhere(
      (QuestType q) => q.name == value,
      orElse: () => QuestType.daily,
    );
  }
}

import 'package:equatable/equatable.dart';

/// Represents a user/player in the system.
///
/// Maps directly to the `users/{uid}` Firestore document.
class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final int xp;
  final int level;
  final int coins;
  final int streakDays;
  final String? avatarUrl;
  final List<String> unlockedAvatars;
  final String? recoveryKey;
  final int totalCorrectAnswers;
  final int totalExamsTaken;
  final DateTime? lastExamCompletedAt;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.xp,
    required this.level,
    this.coins = 0,
    required this.streakDays,
    this.totalCorrectAnswers = 0,
    this.totalExamsTaken = 0,
    this.lastExamCompletedAt,
    this.avatarUrl,
    this.unlockedAvatars = const [],
    this.recoveryKey,
    required this.createdAt,
    required this.lastLoginAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isStudent => role == UserRole.student;

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    int? xp,
    int? level,
    int? coins,
    int? streakDays,
    int? totalCorrectAnswers,
    int? totalExamsTaken,
    DateTime? lastExamCompletedAt,
    String? avatarUrl,
    List<String>? unlockedAvatars,
    String? recoveryKey,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      streakDays: streakDays ?? this.streakDays,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      totalExamsTaken: totalExamsTaken ?? this.totalExamsTaken,
      lastExamCompletedAt: lastExamCompletedAt ?? this.lastExamCompletedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      unlockedAvatars: unlockedAvatars ?? this.unlockedAvatars,
      recoveryKey: recoveryKey ?? this.recoveryKey,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    role,
    xp,
    level,
    coins,
    streakDays,
    totalCorrectAnswers,
    totalExamsTaken,
    lastExamCompletedAt,
    avatarUrl,
    unlockedAvatars,
    recoveryKey,
    createdAt,
    lastLoginAt,
  ];
}

/// User role enum matching Firestore role field.
enum UserRole {
  student,
  admin;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (UserRole role) => role.name == value,
      orElse: () => UserRole.student,
    );
  }
}

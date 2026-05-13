import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/features/quest/data/repositories/quest_repository.dart';
import 'package:bitwise_academy/shared/models/quest_model.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';
import 'package:bitwise_academy/shared/services/user_progress_repository.dart';

// ── Events ──

sealed class QuestEvent extends Equatable {
  const QuestEvent();

  @override
  List<Object?> get props => [];
}

final class LoadActiveQuestsRequested extends QuestEvent {
  const LoadActiveQuestsRequested();
}

final class _ActiveQuestsUpdated extends QuestEvent {
  final List<QuestModel> quests;

  const _ActiveQuestsUpdated({required this.quests});

  @override
  List<Object?> get props => [quests];
}

final class _ActiveQuestsError extends QuestEvent {
  final String message;

  const _ActiveQuestsError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class AwardQuestXp extends QuestEvent {
  final String uid;
  final String questId;
  final int xpAmount;

  const AwardQuestXp({
    required this.uid,
    required this.questId,
    required this.xpAmount,
  });

  @override
  List<Object?> get props => [uid, questId, xpAmount];
}

final class AcknowledgeQuestXpAward extends QuestEvent {
  const AcknowledgeQuestXpAward();
}

/// Cancels the active quest stream and resets state.
/// Dispatched whenever the user logs out.
final class StopQuestListening extends QuestEvent {
  const StopQuestListening();
}

// ── States ──

sealed class QuestState extends Equatable {
  const QuestState();

  @override
  List<Object?> get props => [];
}

final class QuestInitial extends QuestState {
  const QuestInitial();
}

final class QuestLoadInProgress extends QuestState {
  const QuestLoadInProgress();
}

final class QuestLoadSuccess extends QuestState {
  final List<QuestModel> dailyQuests;
  final List<QuestModel> weeklyQuests;
  final Set<String> completedQuestIds;

  const QuestLoadSuccess({
    required this.dailyQuests,
    required this.weeklyQuests,
    this.completedQuestIds = const {},
  });

  @override
  List<Object?> get props => [dailyQuests, weeklyQuests, completedQuestIds];

  QuestLoadSuccess copyWith({
    List<QuestModel>? dailyQuests,
    List<QuestModel>? weeklyQuests,
    Set<String>? completedQuestIds,
  }) {
    return QuestLoadSuccess(
      dailyQuests: dailyQuests ?? this.dailyQuests,
      weeklyQuests: weeklyQuests ?? this.weeklyQuests,
      completedQuestIds: completedQuestIds ?? this.completedQuestIds,
    );
  }
}

final class QuestLoadFailure extends QuestState {
  final String message;

  const QuestLoadFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

final class QuestXpAwarding extends QuestState {
  final QuestModel quest;
  final QuestLoadSuccess previousState;

  const QuestXpAwarding({required this.quest, required this.previousState});

  @override
  List<Object?> get props => [quest, previousState];
}

final class QuestXpAwardSuccess extends QuestState {
  final QuestModel quest;
  final int xpAwarded;
  final int newLevel;
  final UserEntity updatedUser;
  final QuestLoadSuccess previousState;

  const QuestXpAwardSuccess({
    required this.quest,
    required this.xpAwarded,
    required this.newLevel,
    required this.updatedUser,
    required this.previousState,
  });

  @override
  List<Object?> get props => [
    quest,
    xpAwarded,
    newLevel,
    updatedUser,
    previousState,
  ];
}

final class QuestXpAwardFailure extends QuestState {
  final QuestModel quest;
  final String error;
  final QuestLoadSuccess previousState;

  const QuestXpAwardFailure({
    required this.quest,
    required this.error,
    required this.previousState,
  });

  @override
  List<Object?> get props => [quest, error, previousState];
}

// ── BLoC ──

class QuestBloc extends Bloc<QuestEvent, QuestState> {
  final QuestRepository _questRepository;
  final UserProgressRepository _userProgressRepository;
  StreamSubscription<Result<List<QuestModel>>>? _questSubscription;

  QuestBloc({
    required QuestRepository questRepository,
    required UserProgressRepository userProgressRepository,
  }) : _questRepository = questRepository,
       _userProgressRepository = userProgressRepository,
       super(const QuestInitial()) {
    on<LoadActiveQuestsRequested>(_onLoadActiveQuests);
    on<_ActiveQuestsUpdated>(_onActiveQuestsUpdated);
    on<_ActiveQuestsError>(_onActiveQuestsError);
    on<AwardQuestXp>(_onAwardQuestXp);
    on<AcknowledgeQuestXpAward>(_onAcknowledgeQuestXpAward);
    on<StopQuestListening>(_onStopQuestListening);
  }

  @override
  void onTransition(Transition<QuestEvent, QuestState> transition) {
    super.onTransition(transition);
    AppLogger.instance.d(
      'QuestBloc Transition: ${transition.event} -> ${transition.nextState}',
    );
  }

  void _onLoadActiveQuests(
    LoadActiveQuestsRequested event,
    Emitter<QuestState> emit,
  ) {
    emit(const QuestLoadInProgress());

    _questSubscription?.cancel();
    _questSubscription = _questRepository.watchActiveQuests().listen((result) {
      switch (result) {
        case Success(:final data):
          add(_ActiveQuestsUpdated(quests: data));
        case Failure(:final errorMessage):
          add(_ActiveQuestsError(message: errorMessage));
      }
    });
  }

  void _onActiveQuestsUpdated(
    _ActiveQuestsUpdated event,
    Emitter<QuestState> emit,
  ) {
    final daily = event.quests.where((q) => q.type == QuestType.daily).toList();
    final weekly = event.quests
        .where((q) => q.type == QuestType.weekly)
        .toList();

    emit(
      QuestLoadSuccess(
        dailyQuests: daily,
        weeklyQuests: weekly,
        completedQuestIds: const {},
      ),
    );
  }

  void _onActiveQuestsError(
    _ActiveQuestsError event,
    Emitter<QuestState> emit,
  ) {
    emit(QuestLoadFailure(message: event.message));
  }

  Future<void> _onAwardQuestXp(
    AwardQuestXp event,
    Emitter<QuestState> emit,
  ) async {
    // Find the quest by ID from current state.
    QuestModel? targetQuest;
    QuestLoadSuccess? currentSuccessState;

    if (state is QuestLoadSuccess) {
      currentSuccessState = state as QuestLoadSuccess;
      final allQuests = [
        ...currentSuccessState.dailyQuests,
        ...currentSuccessState.weeklyQuests,
      ];
      for (final q in allQuests) {
        if (q.id == event.questId) {
          targetQuest = q;
          break;
        }
      }
    }

    if (targetQuest == null || currentSuccessState == null) {
      emit(QuestLoadFailure(message: 'Quest not found: ${event.questId}'));
      return;
    }

    // Capture non-nullable references for use inside callbacks.
    final QuestModel quest = targetQuest;
    final QuestLoadSuccess prevState = currentSuccessState;

    emit(QuestXpAwarding(quest: quest, previousState: prevState));

    try {
      final result = await _userProgressRepository.awardXp(
        uid: event.uid,
        xpAmount: event.xpAmount,
      );

      switch (result) {
        case Success<UserEntity>(:final data):
          final int newLevel = (data.xp ~/ 500) + 1;
          emit(
            QuestXpAwardSuccess(
              quest: quest,
              xpAwarded: event.xpAmount,
              newLevel: newLevel,
              updatedUser: data,
              previousState: prevState,
            ),
          );
        case Failure<UserEntity>(:final errorMessage):
          emit(
            QuestXpAwardFailure(
              quest: quest,
              error: errorMessage,
              previousState: prevState,
            ),
          );
      }
    } catch (e) {
      AppLogger.instance.e('Award quest XP failed', error: e);
      emit(
        QuestXpAwardFailure(
          quest: quest,
          error: e.toString(),
          previousState: prevState,
        ),
      );
    }
  }

  void _onAcknowledgeQuestXpAward(
    AcknowledgeQuestXpAward event,
    Emitter<QuestState> emit,
  ) {
    if (state is QuestXpAwardSuccess) {
      final success = state as QuestXpAwardSuccess;
      // Emit the previous state but with the new quest ID added to completed IDs if needed.
      // Actually, QuestLoadSuccess in this Bloc currently has empty completedQuestIds because it's managed by the repository watch.
      // But we can at least return to a non-success state to reset the listener.
      emit(success.previousState);
    }
  }

  /// Cancels the Firestore subscription and resets to QuestInitial.
  /// Called when the user logs out to prevent PERMISSION_DENIED errors.
  void _onStopQuestListening(
    StopQuestListening event,
    Emitter<QuestState> emit,
  ) {
    _questSubscription?.cancel();
    _questSubscription = null;
    AppLogger.instance.d('QuestBloc: stream cancelled (user logged out).');
    emit(const QuestInitial());
  }

  @override
  Future<void> close() {
    _questSubscription?.cancel();
    return super.close();
  }
}

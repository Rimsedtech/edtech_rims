import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/features/store/data/models/skin_model.dart';
import 'package:bitwise_academy/features/store/data/repositories/store_repository.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';
import 'package:bitwise_academy/shared/services/user_repository.dart';

// ── States ──

sealed class StoreState extends Equatable {
  const StoreState();
  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
final class StoreInitial extends StoreState {
  const StoreInitial();
}

/// Skins are loaded and available for display.
final class StoreLoaded extends StoreState {
  final List<SkinModel> skins;
  final bool isPurchasing;

  const StoreLoaded({required this.skins, this.isPurchasing = false});

  StoreLoaded copyWith({List<SkinModel>? skins, bool? isPurchasing}) {
    return StoreLoaded(
      skins: skins ?? this.skins,
      isPurchasing: isPurchasing ?? this.isPurchasing,
    );
  }

  @override
  List<Object?> get props => [skins, isPurchasing];
}

/// An error occurred while loading or interacting with the store.
final class StoreError extends StoreState {
  final String message;
  const StoreError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ── Cubit ──

/// Manages avatar store state: loading skins, purchasing, and equipping.
///
/// Replaces the direct repository calls that were previously in
/// [AvatarStorePage], restoring BLoC-pattern consistency across features.
class StoreCubit extends Cubit<StoreState> {
  final StoreRepository _storeRepository;
  final UserRepository _userRepository;

  StreamSubscription<Result<List<SkinModel>>>? _skinsSubscription;

  StoreCubit({
    required StoreRepository storeRepository,
    required UserRepository userRepository,
  }) : _storeRepository = storeRepository,
       _userRepository = userRepository,
       super(const StoreInitial());

  /// Subscribes to the real-time skins stream from Firestore.
  void loadSkins() {
    _skinsSubscription?.cancel();
    _skinsSubscription = _storeRepository.watchSkins().listen(
      (result) {
        switch (result) {
          case Success(:final data):
            AppLogger.instance.i('StoreCubit: received ${data.length} skins');
            emit(StoreLoaded(skins: data));
          case Failure(:final exception):
            AppLogger.instance.e(
              'StoreCubit: skins stream error',
              error: exception,
            );
            emit(StoreError(message: exception.message));
        }
      },
      onError: (Object error) {
        AppLogger.instance.e('StoreCubit: stream onError', error: error);
        emit(StoreError(message: 'Failed to load skins: $error'));
      },
    );
  }

  /// Purchases a skin for the user, deducting coins.
  ///
  /// Returns the updated [UserEntity] on success so the caller
  /// can sync it with [AuthBloc] via [AuthUserUpdated].
  Future<Result<UserEntity>> purchaseSkin({
    required String uid,
    required String skinId,
    required int price,
  }) async {
    final currentState = state;
    if (currentState is StoreLoaded) {
      emit(currentState.copyWith(isPurchasing: true));
    }

    final result = await _userRepository.purchaseAvatar(
      uid: uid,
      avatarId: skinId,
      price: price,
    );

    if (currentState is StoreLoaded) {
      emit(currentState.copyWith(isPurchasing: false));
    }

    return result;
  }

  /// Equips a skin by updating the user's avatar URL.
  ///
  /// Returns a [Result<void>] indicating success or failure.
  Future<Result<void>> equipSkin({
    required String uid,
    required String imageUrl,
  }) async {
    return _userRepository.updateProfile(uid: uid, avatarUrl: imageUrl);
  }

  @override
  Future<void> close() {
    _skinsSubscription?.cancel();
    return super.close();
  }
}

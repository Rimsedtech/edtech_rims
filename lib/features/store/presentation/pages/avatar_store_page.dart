import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/features/store/presentation/cubit/store_cubit.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:bitwise_academy/features/store/data/models/skin_model.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/router/app_router.dart';

class AvatarStorePage extends StatefulWidget {
  const AvatarStorePage({super.key});

  @override
  State<AvatarStorePage> createState() => _AvatarStorePageState();
}

class _AvatarStorePageState extends State<AvatarStorePage> {
  @override
  void initState() {
    super.initState();
    // Rule #2: Register interceptor in initState
    BackButtonInterceptor.add(_myInterceptor, context: context);
  }

  @override
  void dispose() {
    // Rule #2: Remove interceptor in dispose
    BackButtonInterceptor.remove(_myInterceptor);
    super.dispose();
  }

  /// Rule #4: Prioritize internal routing pop checks.
  bool _myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    _handleBackNavigation();
    return true; // Block default OS action
  }

  void _handleBackNavigation() {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      // Fallback to dashboard if no history is available
      context.go(RoutePaths.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          // Ensure on-screen button follows the same logic
          onPressed: _handleBackNavigation,
        ),
        title: Text(
          'AVATAR STORE',
          style: AppTypography.headlineXs.copyWith(color: AppColors.primary),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is AuthLoading || authState is AuthInitial) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text('Entering the Shop...', style: AppTypography.labelLg),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Preparing the collection for you',
                    style: AppTypography.labelSm,
                  ),
                ],
              ),
            );
          }

          if (authState is! AuthAuthenticated) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Please log in to access the store.'),
                  const SizedBox(height: AppSpacing.md),
                  PixelButton(
                    label: 'GO TO LOGIN',
                    onPressed: () => context.go(RoutePaths.login),
                  ),
                ],
              ),
            );
          }

          final user = authState.user;

          return Column(
            children: [
              // User Coin Balance
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                color: AppColors.surfaceContainerLowest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${user.coins} COINS',
                      style: AppTypography.headlineMd.copyWith(
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: BlocBuilder<StoreCubit, StoreState>(
                  builder: (context, storeState) {
                    return switch (storeState) {
                      StoreInitial() => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Loading skins...',
                              style: AppTypography.labelLg,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Browsing the vault...',
                              style: AppTypography.labelMd,
                            ),
                          ],
                        ),
                      ),
                      StoreError(:final message) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'The shop is closed for maintenance',
                              style: AppTypography.headlineSm.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              message,
                              style: AppTypography.labelMd,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        ),
                      ),
                      StoreLoaded(:final skins, :final isPurchasing) =>
                        skins.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'NO SKINS AVAILABLE',
                                      style: AppTypography.headlineSm.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                ),
                              )
                            : Stack(
                                children: [
                                  GridView.builder(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.md,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.70,
                                          crossAxisSpacing: AppSpacing.md,
                                          mainAxisSpacing: AppSpacing.md,
                                        ),
                                    itemCount: skins.length,
                                    itemBuilder: (context, index) {
                                      final skin = skins[index];
                                      final isUnlocked = user.unlockedAvatars
                                          .contains(skin.id);
                                      final isEquipped =
                                          user.avatarUrl == skin.imageUrl;

                                      return _SkinCard(
                                        skin: skin,
                                        isUnlocked: isUnlocked,
                                        isEquipped: isEquipped,
                                        canAfford: user.coins >= skin.price,
                                        onTap: () {
                                          if (isEquipped || isPurchasing) {
                                            return;
                                          }
                                          if (isUnlocked) {
                                            _handleEquip(
                                              user.uid,
                                              skin,
                                            );
                                          } else {
                                            _handlePurchase(
                                              user.uid,
                                              skin,
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                                  if (isPurchasing)
                                    const Positioned.fill(
                                      child: ColoredBox(
                                        color: Colors.black26,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                    };
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handlePurchase(
    String uid,
    SkinModel skin,
  ) async {
    final storeCubit = context.read<StoreCubit>();
    final authBloc = context.read<AuthBloc>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await storeCubit.purchaseSkin(
      uid: uid,
      skinId: skin.id,
      price: skin.price,
    );

    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        authBloc.add(AuthUserUpdated(user: data));
        messenger.showSnackBar(
          const SnackBar(content: Text('Skin purchased successfully!')),
        );
      case Failure(:final exception):
        messenger.showSnackBar(
          SnackBar(content: Text('Purchase failed: ${exception.message}')),
        );
    }
  }

  Future<void> _handleEquip(
    String uid,
    SkinModel skin,
  ) async {
    final storeCubit = context.read<StoreCubit>();
    final authBloc = context.read<AuthBloc>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await storeCubit.equipSkin(
      uid: uid,
      imageUrl: skin.imageUrl,
    );

    if (!mounted) return;

    switch (result) {
      case Success():
        final authState = authBloc.state;
        if (authState is AuthAuthenticated) {
          final updatedUser = authState.user.copyWith(avatarUrl: skin.imageUrl);
          authBloc.add(AuthUserUpdated(user: updatedUser));
        }
      case Failure(:final exception):
        messenger.showSnackBar(
          SnackBar(content: Text('Equip failed: ${exception.message}')),
        );
    }
  }
}

class _SkinCard extends StatelessWidget {
  final SkinModel skin;
  final bool isUnlocked;
  final bool isEquipped;
  final bool canAfford;
  final VoidCallback onTap;

  const _SkinCard({
    required this.skin,
    required this.isUnlocked,
    required this.isEquipped,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(
          color: isEquipped ? AppColors.secondary : AppColors.outlineVariant,
          width: isEquipped ? 4 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildSkinImage(skin, isUnlocked),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            skin.name,
            style: AppTypography.labelLg.copyWith(
              color: isUnlocked ? AppColors.onSurface : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (isEquipped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: AppColors.secondary,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                'EQUIPPED',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSecondary,
                ),
              ),
            )
          else if (isUnlocked)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: PixelButton(
                label: 'EQUIP',
                onPressed: onTap,
                isPrimary: false,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: PixelButton(
                label: '${skin.price} COINS',
                onPressed: canAfford ? onTap : null,
                isPrimary: true,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the skin image safely, supporting both network and local files.
  /// Prevents crashes when a local 'file://' URI is passed to network loaders.
  Widget _buildSkinImage(SkinModel skin, bool isUnlocked) {
    Widget image;

    if (skin.isNetworkImage) {
      image = CachedNetworkImage(
        imageUrl: skin.imageUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) =>
            const Icon(Icons.broken_image_outlined, color: AppColors.error),
      );
    } else if (skin.isLocalImage) {
      try {
        final file = File(Uri.parse(skin.imageUrl).toFilePath());
        image = Image.file(
          file,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image_outlined, color: AppColors.error),
        );
      } catch (e) {
        image = const Icon(Icons.broken_image_outlined, color: AppColors.error);
      }
    } else {
      // Fallback for empty or completely invalid URLs
      image = const Icon(
        Icons.smart_toy_outlined,
        size: 48,
        color: AppColors.outlineVariant,
      );
    }

    if (!isUnlocked) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0, // R
          0.2126, 0.7152, 0.0722, 0, 0, // G
          0.2126, 0.7152, 0.0722, 0, 0, // B
          0, 0, 0, 1, 0, // A
        ]),
        child: image,
      );
    }

    return image;
  }
}

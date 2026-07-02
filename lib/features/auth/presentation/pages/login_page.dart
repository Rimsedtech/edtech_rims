import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/core/widgets/pixel_input.dart';
import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/features/auth/presentation/cubit/auth_form_cubit.dart';
import 'package:bitwise_academy/features/auth/presentation/cubit/auth_form_state.dart';
import 'package:bitwise_academy/core/router/app_router.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

/// Login page matching the Neo-Arcade "Character Authentication Required"
/// design mockup.
///
/// Features:
/// - Starry pixel grid background (primary color)
/// - Pixel-bordered login card with decorative corners
/// - Email + Password fields (arcade-styled)
/// - "START GAME" primary CTA + Google sign-in
/// - Footer links: Create Account / Recover Data
/// - CRT scanline overlay (decorative)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onGoogleSignIn() {
    context.read<AuthFormCubit>().signInWithGoogle();
  }

  void _onAppleSignIn() {
    context.read<AuthFormCubit>().signInWithApple();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthFormCubit, AuthFormState>(
      listener: (BuildContext context, AuthFormState state) {
        // Only handle the recovery key dialog here.
        // All navigation (to dashboard) is handled by the router redirect
        // reacting to AuthBloc state changes. Calling context.go() here at
        // the same time as the router redirect causes a GlobalKey collision.
        if (state is AuthFormSuccess && state.rawRecoveryKey != null) {
          if (context.mounted) {
            _showRecoveryKeyDialog(
              context,
              state.user,
              state.rawRecoveryKey!,
            );
          }
        }
        if (state is AuthFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: AppTypography.bodyLg.copyWith(color: AppColors.onError),
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: const RoundedRectangleBorder(),
            ),
          );
        }
      },
      builder: (BuildContext context, AuthFormState state) {
        final bool isLoading = state is AuthFormLoading;

        return Scaffold(
          backgroundColor: AppColors.primary,
          body: Stack(
            children: [
              // ── Pixel grid background ──
              Positioned.fill(child: CustomPaint(painter: _PixelGridPainter())),

              // ── Floating pixel stars ──
              ..._buildStars(),

              // ── Main content ──
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ── Brand title ──
                          _buildBrandTitle(),
                          const SizedBox(height: AppSpacing.xxl),

                          // ── Login card ──
                          _buildLoginCard(isLoading),
                          const SizedBox(height: AppSpacing.xl),

                          // ── Footer links ──
                          _buildFooterLinks(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── CRT scanline overlay ──
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.03,
                    child: CustomPaint(painter: _CrtScanlinePainter()),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandTitle() {
    return Column(
      children: [
        Image.asset('logo/logo.png', height: 120, fit: BoxFit.contain),
        const SizedBox(height: AppSpacing.md),
        Text(
          'RIMS',
          textAlign: TextAlign.center,
          style: AppTypography.headlineLg.copyWith(
            color: AppColors.secondaryFixed,
            height: 1.6,
            shadows: const [
              Shadow(offset: Offset(4, 4), color: AppColors.primary),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'ROOT INSTITUTE OF MATHEMATICS',
          textAlign: TextAlign.center,
          style: AppTypography.bodyXs.copyWith(
            color: AppColors.secondaryFixed,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'CHARACTER AUTHENTICATION REQUIRED',
          textAlign: TextAlign.center,
          style: AppTypography.bodyXl.copyWith(
            color: AppColors.onPrimaryContainer,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isLoading) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Card body with pixel border (box-shadow simulated)
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            boxShadow: [
              // Top
              BoxShadow(offset: Offset(0, -4), color: AppColors.onSurface),
              // Bottom
              BoxShadow(offset: Offset(0, 4), color: AppColors.onSurface),
              // Left
              BoxShadow(offset: Offset(-4, 0), color: AppColors.onSurface),
              // Right
              BoxShadow(offset: Offset(4, 0), color: AppColors.onSurface),
            ],
          ),
          child: Builder(
            builder: (formContext) => Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header
                  _buildCardHeader(),
                  const SizedBox(height: AppSpacing.xl),

                  // Email field
                  PixelInput(
                    label: 'EMAIL_ADDRESS',
                    hintText: 'ENTER_EMAIL_HERE',
                    suffixIcon: Icons.mail_outline,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (String? v) =>
                        (v?.isEmpty ?? true) ? 'Email required' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Password field
                  PixelInput(
                    label: 'SECRET_KEY',
                    hintText: '********',
                    obscureText: true,
                    suffixIcon: Icons.lock_outline,
                    controller: _passwordController,
                    validator: (String? v) =>
                        (v?.isEmpty ?? true) ? 'Secret key required' : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Start Game button
                  PixelButton(
                    label: 'START GAME',
                    onPressed: isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthFormCubit>().signInWithEmail(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                  );
                            }
                          },
                    isLoading: isLoading,
                    width: double.infinity,
                  ),
                const SizedBox(height: AppSpacing.lg),

                // Divider
                _buildDivider(),
                const SizedBox(height: AppSpacing.lg),

                // Google sign-in button
                PixelButton(
                  label: 'LOGIN WITH GOOGLE',
                  onPressed: isLoading ? null : _onGoogleSignIn,
                  isPrimary: false,
                  icon: Icons.public,
                  width: double.infinity,
                ),
                if (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS) ...[
                  const SizedBox(height: AppSpacing.md),
                  PixelButton(
                    label: 'LOGIN WITH APPLE',
                    onPressed: isLoading ? null : _onAppleSignIn,
                    isPrimary: false,
                    icon: Icons.apple,
                    width: double.infinity,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),

        // Decorative green corners
        ..._buildCorners(),
      ],
    );
  }

  Widget _buildCardHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceDim, width: 4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_box, size: 40, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PLAYER PROFILE',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Text(
                'LV. 01 INITIATE',
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 2, color: AppColors.surfaceDim)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'OR CONNECT VIA',
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(child: Container(height: 2, color: AppColors.surfaceDim)),
      ],
    );
  }

  Widget _buildFooterLinks() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.go('/register'),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  border: Border.all(color: AppColors.primary, width: 4),
                ),
                child: Column(
                  children: [
                    Text(
                      'New Player?',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'CREATE ACCOUNT',
                      style: AppTypography.bodyXl.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: GestureDetector(
              onTap: () {
                context.push(RoutePaths.recovery);
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  border: Border.all(color: AppColors.primary, width: 4),
                ),
                child: Column(
                  children: [
                    Text(
                      'Lost Key?',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'RECOVER DATA',
                      style: AppTypography.bodyXl.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    return [
      Positioned(
        top: -2,
        left: -2,
        child: Container(width: 16, height: 16, color: AppColors.secondary),
      ),
      Positioned(
        top: -2,
        right: -2,
        child: Container(width: 16, height: 16, color: AppColors.secondary),
      ),
      Positioned(
        bottom: -2,
        left: -2,
        child: Container(width: 16, height: 16, color: AppColors.secondary),
      ),
      Positioned(
        bottom: -2,
        right: -2,
        child: Container(width: 16, height: 16, color: AppColors.secondary),
      ),
    ];
  }

  List<Widget> _buildStars() {
    final List<(double, double, double)> stars = [
      (0.15, 0.10, 1.0),
      (0.80, 0.25, 1.0),
      (0.05, 0.60, 0.4),
      (0.90, 0.85, 1.0),
      (0.50, 0.45, 0.2),
      (0.30, 0.70, 1.0),
      (0.45, 0.15, 0.6),
    ];

    return stars.map(((double, double, double) s) {
      return Positioned(
        left: MediaQuery.of(context).size.width * s.$1,
        top: MediaQuery.of(context).size.height * s.$2,
        child: Opacity(
          opacity: s.$3,
          child: Container(
            width: 4,
            height: 4,
            color: AppColors.secondaryFixed,
          ),
        ),
      );
    }).toList();
  }

  void _showRecoveryKeyDialog(
    BuildContext context,
    UserEntity user,
    String rawKey,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _PixelDialog(
        title: 'CHARACTER CREATED',
        message:
            'CRITICAL: Your recovery key is below. Save it immediately. '
            'This is the ONLY way to recover your account if you lose your credentials.',
        recoveryKey: rawKey,
        buttonText: 'I HAVE SAVED MY KEY',
        onPressed: () {
          // Pop the dialog FIRST, using its own context, before the page
          // is unmounted by the AuthAuthenticated → context.go('/') redirect.
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
          // Then dispatch the event — this will emit AuthAuthenticated
          // and trigger the BlocConsumer listener to navigate away.
          if (context.mounted) {
            context.read<AuthBloc>().add(AuthRecoveryKeyDismissed(user: user));
          }
        },
      ),
    );
  }
}

/// Paints a subtle pixel grid overlay.
class _PixelGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.primaryContainer.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    const double gridSize = 32;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints CRT scanline overlay effect.
class _CrtScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF000000).withValues(alpha: 0.25);

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PixelDialog extends StatelessWidget {
  final String title;
  final String message;
  final String recoveryKey;
  final String buttonText;
  final VoidCallback onPressed;

  const _PixelDialog({
    required this.title,
    required this.message,
    required this.recoveryKey,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.onSurface, width: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.bodyMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: SelectableText(
                recoveryKey,
                style: AppTypography.headlineMd.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PixelButton(
              label: buttonText,
              onPressed: onPressed,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }
}

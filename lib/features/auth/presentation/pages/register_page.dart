import 'package:flutter/material.dart';
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
import 'package:bitwise_academy/shared/models/user_entity.dart';

/// Registration page — "Create Your Character" flow.
///
/// Matches the Neo-Arcade editorial style with the same
/// starry background as the login page.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onRegister() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthFormCubit>().createAccountWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthFormCubit, AuthFormState>(
      listener: (BuildContext context, AuthFormState state) {
        if (state is AuthFormSuccess) {
          if (state.rawRecoveryKey != null) {
            if (context.mounted) {
              _showRecoveryKeyDialog(
                context,
                state.user,
                state.rawRecoveryKey!,
              );
            }
          } else {
            if (context.mounted) {
              context.go('/');
            }
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
              // Pixel grid background
              Positioned.fill(child: CustomPaint(painter: _PixelGridPainter())),

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
                          // Brand
                          Image.asset(
                            'logo/logo.png',
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'RIMS',
                            textAlign: TextAlign.center,
                            style: AppTypography.headlineMdLg.copyWith(
                              color: AppColors.secondaryFixed,
                              height: 1.6,
                              shadows: const [
                                Shadow(
                                  offset: Offset(4, 4),
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'CREATE YOUR CHARACTER',
                            style: AppTypography.bodyXl.copyWith(
                              color: AppColors.onPrimaryContainer,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Registration card
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  boxShadow: [
                                    BoxShadow(
                                      offset: Offset(0, -4),
                                      color: AppColors.onSurface,
                                    ),
                                    BoxShadow(
                                      offset: Offset(0, 4),
                                      color: AppColors.onSurface,
                                    ),
                                    BoxShadow(
                                      offset: Offset(-4, 0),
                                      color: AppColors.onSurface,
                                    ),
                                    BoxShadow(
                                      offset: Offset(4, 0),
                                      color: AppColors.onSurface,
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      Container(
                                        padding: const EdgeInsets.only(
                                          bottom: AppSpacing.md,
                                        ),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: AppColors.surfaceDim,
                                              width: 4,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.person_add,
                                              size: 40,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.md,
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'NEW RECRUIT',
                                                  style: AppTypography
                                                      .headlineSm
                                                      .copyWith(
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                ),
                                                Text(
                                                  'CLASS SELECTION',
                                                  style: AppTypography.bodyLg
                                                      .copyWith(
                                                        color: AppColors
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xl),

                                      PixelInput(
                                        label: 'HERO_NAME',
                                        hintText: 'ENTER_HERO_NAME',
                                        suffixIcon: Icons.badge_outlined,
                                        controller: _nameController,
                                        validator: (String? v) =>
                                            (v?.isEmpty ?? true)
                                            ? 'Hero name required'
                                            : null,
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      PixelInput(
                                        label: 'EMAIL_ADDRESS',
                                        hintText: 'ENTER_EMAIL_HERE',
                                        suffixIcon: Icons.mail_outline,
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (String? v) =>
                                            (v?.isEmpty ?? true)
                                            ? 'Email required'
                                            : null,
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      PixelInput(
                                        label: 'SECRET_KEY',
                                        hintText: 'MIN 6 CHARACTERS',
                                        obscureText: true,
                                        suffixIcon: Icons.lock_outline,
                                        controller: _passwordController,
                                        validator: (String? v) {
                                          if (v?.isEmpty ?? true) {
                                            return 'Secret key required';
                                          }
                                          if (v!.length < 6) {
                                            return 'Min 6 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.lg),

                                      PixelInput(
                                        label: 'CONFIRM_KEY',
                                        hintText: 'REPEAT SECRET KEY',
                                        obscureText: true,
                                        suffixIcon: Icons.lock_outline,
                                        controller: _confirmController,
                                        validator: (String? v) {
                                          if (v != _passwordController.text) {
                                            return 'Keys do not match';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.xl),

                                      PixelButton(
                                        label: 'CREATE CHARACTER',
                                        onPressed: isLoading
                                            ? null
                                            : _onRegister,
                                        isLoading: isLoading,
                                        width: double.infinity,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Green corners
                              Positioned(
                                top: -2,
                                left: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                left: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  color: AppColors.secondary,
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Back to login
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHighest,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 4,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Existing Player?',
                                    style: AppTypography.labelMd.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    'RETURN TO LOGIN',
                                    style: AppTypography.bodyXl.copyWith(
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // CRT overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.03,
                    child: CustomPaint(painter: _CrtPainter()),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

class _PixelGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.onPrimary.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const double spacing = 30;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.height, i), paint);
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

class _CrtPainter extends CustomPainter {
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

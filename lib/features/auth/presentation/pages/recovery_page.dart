import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/core/widgets/pixel_input.dart';
import 'package:bitwise_academy/features/auth/presentation/cubit/auth_form_cubit.dart';
import 'package:bitwise_academy/features/auth/presentation/cubit/auth_form_state.dart';

/// Page for account recovery using a 12-character recovery key.
class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});

  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _onRecover() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthFormCubit>().recoverAccount(
        email: _emailController.text.trim(),
        recoveryKey: _keyController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthFormCubit, AuthFormState>(
      listener: (context, state) {
        if (state is AuthFormPasswordResetSent) {
          if (context.mounted) {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (context) => _PixelDialog(
                title: 'SIGNAL SENT',
                message:
                    'A password reset link has been dispatched to your subspace terminal (email). Check it to regain access.',
                buttonText: 'ACKNOWLEDGED',
                onPressed: () {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  context.go('/login');
                },
              ),
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
      builder: (context, state) {
        final bool isLoading = state is AuthFormLoading;

        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
              onPressed: () => context.pop(),
            ),
          ),
          body: Stack(
            children: [
              // Pixel grid background
              Positioned.fill(child: CustomPaint(painter: _PixelGridPainter())),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.onSurface, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.onSurface.withValues(alpha: 0.2),
                          offset: const Offset(8, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'ACCOUNT RECOVERY',
                            style: AppTypography.headlineMd.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'ENTER YOUR CREDENTIALS TO REGAIN ACCESS',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurface.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          PixelInput(
                            controller: _emailController,
                            label: 'REGISTERED EMAIL',
                            hintText: 'user@bitwiseacademy.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'EMAIL REQUIRED';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          PixelInput(
                            controller: _keyController,
                            label: '12-CHAR RECOVERY KEY',
                            hintText: 'XXXX-XXXX-XXXX',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'RECOVERY KEY REQUIRED';
                              }
                              if (value.length < 12) {
                                return 'INVALID KEY LENGTH';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          PixelButton(
                            label: isLoading ? 'PROCESSING...' : 'RECOVER DATA',
                            onPressed: isLoading ? null : _onRecover,
                            isPrimary: true,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          Text(
                            'WARNING: IF YOU LOST YOUR KEY, YOU MUST CONTACT AN ADMINISTRATOR.',
                            style: AppTypography.headlineXs.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PixelDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _PixelDialog({
    required this.title,
    required this.message,
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

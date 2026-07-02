import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/core/widgets/pixel_card.dart';

/// Configuration result returned when the user confirms their mock test setup.
class MockTestConfig {
  final String subject;
  final String group;

  const MockTestConfig({
    required this.subject,
    required this.group,
  });
}

/// Shows a Neo-Arcade styled bottom sheet for configuring a random mock test.
///
/// Returns a [MockTestConfig] if the user confirms, or `null` if dismissed.
Future<MockTestConfig?> showMockTestConfigSheet(BuildContext context) {
  return showModalBottomSheet<MockTestConfig>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _MockTestConfigSheet(),
  );
}

class _MockTestConfigSheet extends StatefulWidget {
  const _MockTestConfigSheet();

  @override
  State<_MockTestConfigSheet> createState() => _MockTestConfigSheetState();
}

class _MockTestConfigSheetState extends State<_MockTestConfigSheet> {
  String? _selectedSubject;
  String? _selectedGroup;

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _metadataStream;

  @override
  void initState() {
    super.initState();
    _metadataStream = FirebaseFirestore.instance
        .collection('metadata')
        .doc('mock_test_config')
        .snapshots();
  }

  bool get _isValid => _selectedSubject != null && _selectedGroup != null;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _metadataStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: bottomPadding,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
            ),
            child: SafeArea(
              child: PixelCard(
                borderColor: AppColors.error,
                backgroundColor: AppColors.surface,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'SERVER CONNECTION ERROR.\nPlease check your internet or try again later.',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineSm.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PixelButton(
                      label: 'CLOSE',
                      onPressed: () => Navigator.of(context).pop(),
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = snapshot.data?.data() ?? {};
        final List<String> subjects = List<String>.from(
          (data['subjects'] as List<dynamic>?) ?? [],
        );
        final Map<String, dynamic> subjectGroupsMap =
            data['subjectGroups'] as Map<String, dynamic>? ?? {};

        // Filter out empty options
        subjects.removeWhere((s) => s.isEmpty);

        return Container(
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.primary, width: 4),
              left: BorderSide(color: AppColors.primary, width: 4),
              right: BorderSide(color: AppColors.primary, width: 4),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Handle bar ──
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      color: AppColors.outlineVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Title ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    color: AppColors.primary,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: AppColors.secondaryFixed,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'CONFIGURE MOCK TEST',
                          style: AppTypography.headlineXs.copyWith(
                            color: AppColors.secondaryFixed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Test Series selector ──
                  _buildSectionLabel('TEST SERIES'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPixelDropdown<String>(
                    value: _selectedSubject,
                    hint: 'Select test series...',
                    items: subjects,
                    labelBuilder: (s) => s.toUpperCase(),
                    onChanged: (v) {
                      setState(() {
                        _selectedSubject = v;
                        _selectedGroup = null;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Topic selector ──
                  _buildSectionLabel('TOPIC'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPixelDropdown<String>(
                    value: _selectedGroup,
                    hint: 'Select topic...',
                    items: _selectedSubject != null
                        ? List<String>.from(
                            subjectGroupsMap[_selectedSubject!]
                                    as Iterable<dynamic>? ??
                                [],
                          )
                        : [],
                    labelBuilder: (s) => s.toUpperCase(),
                    onChanged: _selectedSubject != null
                        ? (v) => setState(() => _selectedGroup = v)
                        : (v) {},
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Start button ──
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isValid ? 1.0 : 0.4,
                    child: PixelButton(
                      label: 'START MISSION',
                      icon: Icons.play_arrow,
                      width: double.infinity,
                      onPressed: _isValid
                          ? () {
                              Navigator.of(context).pop(
                                MockTestConfig(
                                  subject: _selectedSubject!,
                                  group: _selectedGroup!,
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTypography.headlineXs.copyWith(color: AppColors.primary),
    );
  }

  Widget _buildPixelDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(
          color: value != null ? AppColors.primary : AppColors.outlineVariant,
          width: value != null ? 3 : 2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceContainerLowest,
          hint: Text(
            hint,
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.primary,
            size: 28,
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelBuilder(item),
                style: AppTypography.headlineXs.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

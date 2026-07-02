import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/features/jobs/data/models/job_advertisement.dart';

/// Displays a single MPSC advertisement in the dashboard.
///
/// Tapping "VIEW PDF" opens the PDF link via the device browser using
/// [url_launcher]. The card uses [PixelCard]-style borders for visual
/// consistency with the rest of the UI.
class JobAdvertisementCard extends StatelessWidget {
  final JobAdvertisement job;

  const JobAdvertisementCard({required this.job, super.key});

  Future<void> _openPdf() async {
    final uri = Uri.tryParse(job.pdfLink);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastDateKnown = job.lastDate != 'Check PDF';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.outlineVariant, width: 1.5),
        boxShadow: const [
          BoxShadow(offset: Offset(3, 3), color: AppColors.shadowTinted),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Department badge ──
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            color: AppColors.primaryContainer,
            child: Text(
              job.department.toUpperCase(),
              style: AppTypography.headlineXxs.copyWith(
                color: AppColors.onPrimaryContainer,
                fontSize: 9,
                letterSpacing: 0.8,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Title ──
          Text(
            job.title,
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Last Date row ──
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 12,
                color: isLastDateKnown ? AppColors.secondary : AppColors.outline,
              ),
              const SizedBox(width: 4),
              Text(
                isLastDateKnown
                    ? 'Last Date: ${job.lastDate}'
                    : 'Last Date: Check PDF',
                style: AppTypography.labelMd.copyWith(
                  color: isLastDateKnown
                      ? AppColors.onSecondaryContainer
                      : AppColors.onSurfaceVariant,
                  fontWeight:
                      isLastDateKnown ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── View PDF Button ──
          PixelButton(
            label: 'VIEW PDF',
            icon: Icons.picture_as_pdf_outlined,
            width: double.infinity,
            isPrimary: false,
            onPressed: _openPdf,
          ),
        ],
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class JobsSkeleton extends StatefulWidget {
  const JobsSkeleton({super.key});

  @override
  State<JobsSkeleton> createState() => _JobsSkeletonState();
}

class _JobsSkeletonState extends State<JobsSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _bar(double width, double height) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (_, __) => Opacity(
        opacity: _fade.value,
        child: Container(
          width: width,
          height: height,
          color: AppColors.surfaceContainerHighest,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border.all(color: AppColors.outlineVariant, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(80, 14),
              const SizedBox(height: AppSpacing.sm),
              _bar(double.infinity, 16),
              const SizedBox(height: 6),
              _bar(200, 12),
              const SizedBox(height: AppSpacing.sm),
              _bar(120, 12),
              const SizedBox(height: AppSpacing.md),
              _bar(double.infinity, 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class JobsEmptyState extends StatelessWidget {
  const JobsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          const Icon(
            Icons.campaign_outlined,
            size: 40,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'NO ACTIVE ADVERTISEMENTS',
            style: AppTypography.headlineXs.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Check back soon for new MPSC postings.',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class JobsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const JobsErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 36, color: AppColors.error),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'FAILED TO LOAD',
            style: AppTypography.headlineXs.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          PixelButton(
            label: 'RETRY',
            icon: Icons.refresh,
            isPrimary: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

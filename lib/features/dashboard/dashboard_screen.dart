import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/app/theme/app_tokens.dart';
import 'package:voltly/features/dashboard/telemetry_diagnostics_screen.dart';

/// Voltly's current app shell.
///
/// Phase 0 provides branding, theming and a launchable Android app. No battery
/// value is rendered here: device readings must come from the native telemetry
/// service introduced in Phase 1, never from demo data.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double minContentHeight = math.max(
              0,
              constraints.maxHeight - AppSpacing.md - AppSpacing.lg,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 560,
                    minHeight: minContentHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const _BrandHeader(),
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            'Know your battery.',
                            style: textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Battery intelligence, beautifully simple.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const _FoundationNotice(),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.xl),
                        child: _PrivacyNote(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.mintContainer,
            borderRadius: AppRadius.control,
            border: Border.all(color: AppColors.outline),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: AppColors.mint,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'VOLTLY',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(letterSpacing: 3.2, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _FoundationNotice extends StatelessWidget {
  const _FoundationNotice();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.mintContainer,
                    borderRadius: AppRadius.control,
                  ),
                  child: const Icon(
                    Icons.sensors_rounded,
                    color: AppColors.mint,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Telemetry connected', style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'The native adapter is live. Live dashboard metrics '
                        'arrive in the next milestone; open diagnostics to '
                        'inspect real readings, availability and provenance.',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            const _CapabilityRow(
              label: 'Native telemetry adapter ready',
              isComplete: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            const _CapabilityRow(
              label: 'Next: dashboard metrics and states',
              isComplete: false,
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          const TelemetryDiagnosticsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.developer_mode_rounded, size: 18),
                label: const Text('Open telemetry diagnostics'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.label, required this.isComplete});

  final String label;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          isComplete
              ? Icons.check_circle_outline_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: isComplete ? AppColors.mint : AppColors.textTertiary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isComplete
                  ? AppColors.textSecondary
                  : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Android 8.0+ · Local-first. No account, no tracking.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

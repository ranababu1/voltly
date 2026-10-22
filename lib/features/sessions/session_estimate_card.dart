import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/app/theme/app_tokens.dart';
import 'package:voltly/core/sessions/battery_time_estimate.dart';
import 'package:voltly/core/sessions/estimate_presentation.dart';
import 'package:voltly/core/sessions/session_providers.dart';

/// Approximate time-to-full/empty for the active session, or an explicit reason
/// when the stored evidence is insufficient.
class SessionEstimateCard extends ConsumerWidget {
  const SessionEstimateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BatteryEstimateResult?> result = ref.watch(
      activeSessionEstimateProvider,
    );
    return result.when(
      data: (BatteryEstimateResult? value) {
        if (value == null) return const SizedBox.shrink();
        final BatteryTimeEstimate? estimate = value.estimate;
        if (estimate == null) {
          return _UnavailableEstimate(reason: value.reason!);
        }
        return _AvailableEstimate(estimate: estimate);
      },
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stackTrace) =>
          const _UnavailableEstimate(
            reason: 'Stored session samples are unavailable right now.',
          ),
    );
  }
}

class _AvailableEstimate extends StatelessWidget {
  const _AvailableEstimate({required this.estimate});

  final BatteryTimeEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? coverage = estimateCoverageNote(estimate);

    return Semantics(
      container: true,
      label: estimateSemantics(estimate),
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.mint,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        estimateTitle(estimate.kind),
                        style: textTheme.titleMedium,
                      ),
                    ),
                    const _EstimateBadge(),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  formatBatteryEstimateTime(estimate),
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(estimateAssumption(estimate), style: textTheme.bodySmall),
                if (coverage != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(coverage, style: textTheme.bodySmall),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Calculated estimate; not charger input power, capacity or '
                  'battery health.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnavailableEstimate extends StatelessWidget {
  const _UnavailableEstimate({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Battery time estimate unavailable. $reason',
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.timelapse_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Time estimate unavailable',
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(reason, style: textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EstimateBadge extends StatelessWidget {
  const _EstimateBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.mint.withValues(alpha: 0.08),
        borderRadius: AppRadius.control,
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Estimated',
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppColors.mint),
      ),
    );
  }
}

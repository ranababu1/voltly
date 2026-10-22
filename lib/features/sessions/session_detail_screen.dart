import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/app/theme/app_tokens.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/session_chart_data.dart';
import 'package:voltly/core/sessions/session_detail.dart';
import 'package:voltly/core/sessions/session_presentation.dart';
import 'package:voltly/core/sessions/session_providers.dart';
import 'package:voltly/features/sessions/session_trend_chart.dart';

/// Detailed stored history for one session, including gap-aware trends.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SessionDetail?> detail = ref.watch(
      sessionDetailProvider(sessionId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Session detail')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(sessionDetailProvider(sessionId));
            try {
              await ref.read(sessionDetailProvider(sessionId).future);
            } catch (_) {
              // The error state is rendered from the provider.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: <Widget>[
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: detail.when(
                    data: (SessionDetail? value) => value == null
                        ? const _NotFound()
                        : _DetailBody(detail: value),
                    loading: () => const _DetailLoading(),
                    error: (Object error, StackTrace stackTrace) =>
                        _DetailError(
                          error: error,
                          onRetry: () =>
                              ref.invalidate(sessionDetailProvider(sessionId)),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final SessionDetail detail;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ChargingSession session = detail.session;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          container: true,
          label: sessionSemantics(session),
          child: ExcludeSemantics(child: _SummaryCard(session: session)),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Stored trends', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Only samples retained in the local database are plotted. Gaps, '
          'unavailable values and pruned history are never filled in.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final SessionChartMetric metric in SessionChartMetric.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SessionTrendCard(
              metric: metric,
              samples: detail.samples,
              session: session,
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Battery-side power is calculated and approximate, not charger '
          'input power.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.session});

  final ChargingSession session;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool active = session.isActive;
    final Color stateColor = switch (session.state) {
      ChargingSessionState.active => AppColors.mint,
      ChargingSessionState.completed => AppColors.textPrimary,
      ChargingSessionState.interrupted => AppColors.warning,
    };
    final List<String> coverage = <String>[
      if (session.hasSamplingGaps) 'Telemetry gaps',
      if (session.samplesPruned) 'Older samples pruned',
      if (session.state == ChargingSessionState.interrupted) 'Partial session',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    active
                        ? Icons.battery_charging_full_rounded
                        : Icons.battery_std_rounded,
                    color: stateColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            sessionStateLabel(session),
                            style: textTheme.titleMedium,
                          ),
                          _DetailPill(
                            label: active ? 'Live' : 'Stored',
                            color: active
                                ? AppColors.mint
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sessionEndLabel(session),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Started ${formatSessionDateTime(session.startedAt)}',
              style: textTheme.bodySmall,
            ),
            if (session.endedAt != null)
              Text(
                'Ended ${formatSessionDateTime(session.endedAt!)}',
                style: textTheme.bodySmall,
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                _DetailFact(
                  label: 'Start',
                  value: formatSessionLevel(session.startLevelPercent),
                ),
                _DetailFact(
                  label: 'End',
                  value: active
                      ? 'In progress'
                      : formatSessionLevel(session.endLevelPercent),
                ),
                _DetailFact(
                  label: 'Change',
                  value: formatSessionLevelChange(session),
                ),
                _DetailFact(
                  label: 'Duration',
                  value: session.duration == null
                      ? 'In progress'
                      : formatSessionDuration(session.duration!),
                ),
                _DetailFact(label: 'Samples', value: '${session.sampleCount}'),
              ],
            ),
            if (coverage.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: <Widget>[
                  for (final String label in coverage)
                    _DetailPill(label: label, color: AppColors.warning),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: <Widget>[
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loading session…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Session detail unavailable',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              describeSessionStorageError(error),
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.search_off_rounded,
              color: AppColors.textSecondary,
              size: 30,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Session not found',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This session may have been removed by retention or local '
              'history may have been cleared.',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailFact extends StatelessWidget {
  const _DetailFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: textTheme.titleSmall),
      ],
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.control,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

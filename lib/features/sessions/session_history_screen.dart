import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/app/theme/app_tokens.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/session_presentation.dart';
import 'package:voltly/core/sessions/session_providers.dart';
import 'package:voltly/features/sessions/session_detail_screen.dart';

/// Local charging-session history.
///
/// The list only shows stored sessions. It never claims continuous coverage
/// when telemetry gaps, interrupted endings or retention pruning are present.
class SessionHistoryScreen extends ConsumerWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ChargingSession>> history = ref.watch(
      sessionHistoryProvider,
    );
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Charging sessions')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(sessionHistoryProvider);
            try {
              await ref.read(sessionHistoryProvider.future);
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text('Session history', style: textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Recorded only while Voltly is open. Gaps, interrupted '
                        'sessions and pruned samples are shown explicitly.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      history.when(
                        data: (List<ChargingSession> sessions) =>
                            _SessionList(sessions: sessions),
                        loading: () => const _HistoryLoading(),
                        error: (Object error, StackTrace stackTrace) =>
                            _HistoryError(
                              error: error,
                              onRetry: () =>
                                  ref.invalidate(sessionHistoryProvider),
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
    );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

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
              'Loading sessions…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.error, required this.onRetry});

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
              'Session history unavailable',
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

class _SessionList extends StatelessWidget {
  const _SessionList({required this.sessions});

  final List<ChargingSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const _EmptyHistory();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final ChargingSession session in sessions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SessionCard(
              session: session,
              onTap: session.id == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              SessionDetailScreen(sessionId: session.id!),
                        ),
                      );
                    },
            ),
          ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.battery_charging_full_rounded,
              color: AppColors.textSecondary,
              size: 30,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No charging sessions yet',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Start charging while Voltly is open to record a session. '
              'Background time is never filled in or treated as continuous.',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, this.onTap});

  final ChargingSession session;
  final VoidCallback? onTap;

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

    return Semantics(
      container: true,
      button: onTap != null,
      onTap: onTap,
      label: sessionSemantics(session),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
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
                                _StatusPill(
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
                      _SessionFact(
                        label: 'Start',
                        value: formatSessionLevel(session.startLevelPercent),
                      ),
                      _SessionFact(
                        label: 'End',
                        value: active
                            ? 'In progress'
                            : formatSessionLevel(session.endLevelPercent),
                      ),
                      _SessionFact(
                        label: 'Change',
                        value: formatSessionLevelChange(session),
                      ),
                      _SessionFact(
                        label: 'Duration',
                        value: session.duration == null
                            ? 'In progress'
                            : formatSessionDuration(session.duration!),
                      ),
                      _SessionFact(
                        label: 'Samples',
                        value: '${session.sampleCount}',
                      ),
                    ],
                  ),
                  if (coverage.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      children: <Widget>[
                        for (final String label in coverage)
                          _StatusPill(label: label, color: AppColors.warning),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionFact extends StatelessWidget {
  const _SessionFact({required this.label, required this.value});

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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

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

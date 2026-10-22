import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/app/theme/app_tokens.dart';
import 'package:voltly/core/sessions/session_providers.dart';
import 'package:voltly/core/telemetry/battery_power.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';
import 'package:voltly/features/charging_screen/charging_screen_settings_card.dart';
import 'package:voltly/features/dashboard/telemetry_diagnostics_screen.dart';
import 'package:voltly/features/dashboard/telemetry_presentation.dart';
import 'package:voltly/features/sessions/session_estimate_card.dart';
import 'package:voltly/features/sessions/session_history_screen.dart';
import 'package:voltly/features/sessions/session_widgets.dart';

/// Voltly's telemetry-driven battery dashboard.
///
/// Every value is rendered from [telemetrySnapshotProvider]; there are no demo
/// readings. Loading, error, unsupported, invalid and stale states are explicit
/// and an unavailable metric is never displayed as zero.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TelemetrySnapshot> snapshot = ref.watch(
      telemetrySnapshotProvider,
    );
    final SessionTrackingState tracking = ref.watch(sessionTrackingProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double minContentHeight = math.max(
              0,
              constraints.maxHeight - AppSpacing.md - AppSpacing.lg,
            );

            return RefreshIndicator(
              onRefresh: () async {
                ref.read(telemetrySnapshotProvider.notifier).retry();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            _DashboardHeader(
                              onOpenHistory: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) =>
                                        const SessionHistoryScreen(),
                                  ),
                                );
                              },
                              onOpenDiagnostics: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (BuildContext context) =>
                                        const TelemetryDiagnosticsScreen(),
                                  ),
                                );
                              },
                            ),
                            if (tracking.hasError) ...<Widget>[
                              const SizedBox(height: AppSpacing.md),
                              SessionStorageErrorBanner(
                                error: tracking.error!,
                                onRetry: () {
                                  unawaited(
                                    ref
                                        .read(sessionTrackingProvider.notifier)
                                        .retry(),
                                  );
                                },
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'Battery overview',
                              style: textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Live readings from this device.',
                              style: textTheme.bodyMedium,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            snapshot.when(
                              data: (TelemetrySnapshot data) =>
                                  _DashboardData(snapshot: data),
                              loading: () => const _DashboardLoading(),
                              error: (Object error, StackTrace stackTrace) =>
                                  _DashboardError(
                                    error: error,
                                    onRetry: () => ref
                                        .read(
                                          telemetrySnapshotProvider.notifier,
                                        )
                                        .retry(),
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const ChargingScreenSettingsCard(),
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.onOpenHistory,
    required this.onOpenDiagnostics,
  });

  final VoidCallback onOpenHistory;
  final VoidCallback onOpenDiagnostics;

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
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'VOLTLY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 3.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onOpenHistory,
          tooltip: 'Charging sessions',
          icon: const Icon(
            Icons.history_rounded,
            color: AppColors.textSecondary,
          ),
        ),
        IconButton(
          onPressed: onOpenDiagnostics,
          tooltip: 'Telemetry diagnostics',
          icon: const Icon(
            Icons.developer_mode_rounded,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DashboardData extends StatelessWidget {
  const _DashboardData({required this.snapshot});

  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final TelemetryReading<double> power = calculateBatteryPower(snapshot);

    return TelemetryFreshnessBuilder(
      observedAt: snapshot.observedAt,
      builder: (BuildContext context, bool isStale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _PrimaryBatteryCard(snapshot: snapshot, isStale: isStale),
          const SizedBox(height: AppSpacing.md),
          const SessionEstimateCard(),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double cardWidth = constraints.maxWidth >= 480
                  ? (constraints.maxWidth - AppSpacing.sm) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  SizedBox(
                    width: cardWidth,
                    child: _MetricCard(
                      label: 'Voltage',
                      icon: Icons.bolt,
                      reading: snapshot.voltage,
                      value: formatTelemetryNumeric(snapshot.voltage, 2, 'V'),
                      spokenValue: spokenTelemetryNumeric(
                        snapshot.voltage,
                        2,
                        'volts',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MetricCard(
                      label: 'Temperature',
                      icon: Icons.thermostat,
                      reading: snapshot.temperature,
                      value: formatTelemetryNumeric(
                        snapshot.temperature,
                        1,
                        '°C',
                      ),
                      spokenValue: spokenTelemetryNumeric(
                        snapshot.temperature,
                        1,
                        'degrees Celsius',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MetricCard(
                      label: 'Current now',
                      icon: Icons.show_chart,
                      reading: snapshot.currentNow,
                      value: formatTelemetryNumeric(
                        snapshot.currentNow,
                        3,
                        'A',
                      ),
                      spokenValue: spokenTelemetryNumeric(
                        snapshot.currentNow,
                        3,
                        'amperes',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MetricCard(
                      label: 'Average current',
                      icon: Icons.history,
                      reading: snapshot.currentAverage,
                      value: formatTelemetryNumeric(
                        snapshot.currentAverage,
                        3,
                        'A',
                      ),
                      spokenValue: spokenTelemetryNumeric(
                        snapshot.currentAverage,
                        3,
                        'amperes',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _MetricCard(
                      label: 'Charge counter',
                      icon: Icons.battery_std,
                      reading: snapshot.chargeCounter,
                      value: formatTelemetryNumeric(
                        snapshot.chargeCounter,
                        1,
                        'mAh',
                      ),
                      spokenValue: spokenTelemetryNumeric(
                        snapshot.chargeCounter,
                        1,
                        'milliampere hours',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _PowerSummaryCard(power: power),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Values are device-reported unless marked calculated. '
            'Unavailable metrics are shown explicitly, never as zero.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PrimaryBatteryCard extends StatelessWidget {
  const _PrimaryBatteryCard({required this.snapshot, required this.isStale});

  final TelemetrySnapshot snapshot;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TelemetryReading<double> level = snapshot.batteryLevel;
    final TelemetryReading<BatteryChargingState> state = snapshot.chargingState;
    final TelemetryReading<BatteryPlugSource> plug = snapshot.plugSource;
    final bool levelAvailable = level.isAvailable;
    final double? levelValue = level.value;
    final BatteryChargingState? stateValue = state.value;
    final String chargingSemantics = _chargingSemantics(state, plug);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'BATTERY LEVEL',
                    style: textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TelemetryBadge(
                  label: isStale ? 'Stale' : 'Live',
                  color: isStale ? AppColors.warning : AppColors.mint,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              container: true,
              label: levelAvailable && levelValue != null
                  ? 'Battery level ${levelValue.round()} percent'
                  : 'Battery level unavailable',
              child: ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    levelAvailable && levelValue != null
                        ? formatBatteryPercent(levelValue)
                        : 'Battery level unavailable',
                    style: levelAvailable
                        ? textTheme.displayLarge
                        : textTheme.titleLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                  ),
                ),
              ),
            ),
            if (levelAvailable && levelValue != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: AppRadius.pill,
                  child: LinearProgressIndicator(
                    value: levelValue.clamp(0.0, 100.0).toDouble() / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceElevated,
                    color: AppColors.mint,
                  ),
                ),
              ),
            ] else if (level.reason != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(level.reason!, style: textTheme.bodySmall),
            ],
            const SizedBox(height: AppSpacing.md),
            Semantics(
              container: true,
              label: chargingSemantics,
              child: ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ChargingPulse(
                      active: stateValue == BatteryChargingState.charging,
                      child: Icon(
                        _stateIcon(stateValue),
                        color: _stateColor(stateValue),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            state.isAvailable
                                ? formatTelemetryChargingState(state)
                                : 'Charging state unavailable',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plug.isAvailable
                                ? 'Power source: ${formatTelemetryPlugSource(plug)}'
                                : 'Power source unavailable',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (!state.isAvailable &&
                              state.reason != null) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(state.reason!, style: textTheme.bodySmall),
                          ],
                          if (!plug.isAvailable &&
                              plug.reason != null) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(plug.reason!, style: textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                TelemetryBadge(
                  label: telemetrySourceLabel(level.source),
                  color: telemetrySourceColor(level.source),
                ),
                Text(
                  'Observed ${formatTelemetryDateTime(snapshot.observedAt)}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            if (isStale) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              const _StaleWarning(),
            ],
          ],
        ),
      ),
    );
  }
}

String _chargingSemantics(
  TelemetryReading<BatteryChargingState> state,
  TelemetryReading<BatteryPlugSource> plug,
) {
  final String stateText = state.isAvailable
      ? formatTelemetryChargingState(state)
      : 'Charging state unavailable';
  final String plugText = plug.isAvailable
      ? formatTelemetryPlugSource(plug)
      : 'Power source unavailable';
  final StringBuffer buffer = StringBuffer(
    'Charging state: $stateText. Power source: $plugText.',
  );
  if (!state.isAvailable && state.reason != null) {
    buffer.write(' ${state.reason}');
  }
  if (!plug.isAvailable && plug.reason != null) {
    buffer.write(' ${plug.reason}');
  }
  return buffer.toString();
}

IconData _stateIcon(BatteryChargingState? state) => switch (state) {
  BatteryChargingState.charging => Icons.battery_charging_full,
  BatteryChargingState.full => Icons.battery_full,
  BatteryChargingState.discharging => Icons.battery_5_bar,
  BatteryChargingState.notCharging => Icons.power_off,
  null => Icons.battery_unknown,
};

Color _stateColor(BatteryChargingState? state) => switch (state) {
  BatteryChargingState.charging || BatteryChargingState.full => AppColors.mint,
  BatteryChargingState.discharging => AppColors.textSecondary,
  BatteryChargingState.notCharging => AppColors.warning,
  null => AppColors.textTertiary,
};

class _StaleWarning extends StatelessWidget {
  const _StaleWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: AppRadius.control,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.schedule, color: AppColors.warning, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'This reading is over 5 minutes old. Values may be stale.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.icon,
    required this.reading,
    required this.value,
    required this.spokenValue,
  });

  final String label;
  final IconData icon;
  final TelemetryReading<Object> reading;
  final String value;

  /// Screen-reader-friendly value, e.g. "4.20 volts".
  final String spokenValue;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool available = reading.isAvailable;
    final String semanticsLabel =
        '$label, $spokenValue, '
        '${telemetryAvailabilityLabel(reading.availability)}, '
        '${telemetrySourceLabel(reading.source)}'
        '${!available && reading.reason != null ? '. ${reading.reason}' : ''}';

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      icon,
                      size: 18,
                      color: available
                          ? AppColors.mint
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        label,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  style: textTheme.titleLarge?.copyWith(
                    color: available
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    TelemetryBadge(
                      label: telemetryAvailabilityLabel(reading.availability),
                      color: telemetryAvailabilityColor(reading.availability),
                    ),
                    TelemetryBadge(
                      label: telemetrySourceLabel(reading.source),
                      color: telemetrySourceColor(reading.source),
                    ),
                  ],
                ),
                if (!available && reading.reason != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(reading.reason!, style: textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerSummaryCard extends StatelessWidget {
  const _PowerSummaryCard({required this.power});

  final TelemetryReading<double> power;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool available = power.isAvailable;
    final String semanticsLabel =
        'Battery-side power, ${spokenTelemetryNumeric(power, 2, 'watts')}, '
        '${telemetrySourceLabel(power.source)}, '
        '${telemetryAvailabilityLabel(power.availability)}. '
        'Approximate battery-side power, not charger input power.'
        '${!available && power.reason != null ? ' ${power.reason}' : ''}';

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.bolt, size: 18, color: AppColors.mint),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Battery-side power',
                        style: textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatTelemetryNumeric(power, 2, 'W'),
                  style: textTheme.titleLarge?.copyWith(
                    color: available
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    TelemetryBadge(
                      label: telemetrySourceLabel(power.source),
                      color: telemetrySourceColor(power.source),
                    ),
                    TelemetryBadge(
                      label: telemetryAvailabilityLabel(power.availability),
                      color: telemetryAvailabilityColor(power.availability),
                    ),
                    Text(
                      'Observed ${formatTelemetryTime(power.observedAt)}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Calculated from voltage × current. Approximate battery-side '
                  'power, not wall-charger or adapter input power.',
                  style: textTheme.bodySmall,
                ),
                if (!available && power.reason != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(power.reason!, style: textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: <Widget>[
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Reading battery…',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Listening for Android battery updates. Readings stay on this '
              'device.',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.error, required this.onRetry});

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
            const Icon(Icons.error_outline, color: AppColors.danger, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Telemetry unavailable',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              describeTelemetryError(error),
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
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
            Icons.lock_outline,
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

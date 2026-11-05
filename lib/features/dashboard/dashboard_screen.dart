import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/app/theme/app_tokens.dart';
import 'package:voltly/app/theme/app_typography.dart';
import 'package:voltly/core/sessions/session_providers.dart';
import 'package:voltly/core/telemetry/battery_power.dart';
import 'package:voltly/core/telemetry/live_current.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';
import 'package:voltly/features/charging_screen/charging_screen_settings_card.dart';
import 'package:voltly/features/dashboard/dashboard_painters.dart';
import 'package:voltly/features/dashboard/telemetry_diagnostics_screen.dart';
import 'package:voltly/features/dashboard/telemetry_presentation.dart';
import 'package:voltly/features/sessions/session_estimate_card.dart';
import 'package:voltly/features/sessions/session_history_screen.dart';
import 'package:voltly/features/sessions/session_widgets.dart';

/// Voltly's telemetry-driven battery dashboard.
///
/// Every value is rendered from [telemetrySnapshotProvider] and the in-memory
/// [liveCurrentProvider]; there are no demo readings. Loading, error,
/// unsupported, invalid and stale states are explicit and an unavailable
/// metric is never displayed as zero.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TelemetrySnapshot> snapshot = ref.watch(
      telemetrySnapshotProvider,
    );
    final SessionTrackingState tracking = ref.watch(sessionTrackingProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.mint,
          backgroundColor: AppColors.surfaceElevated,
          onRefresh: () async {
            ref.read(telemetrySnapshotProvider.notifier).retry();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _DashboardHeader(
                      onOpenHistory: () =>
                          _push(context, const SessionHistoryScreen()),
                      onOpenDiagnostics: () =>
                          _push(context, const TelemetryDiagnosticsScreen()),
                    ),
                    if (tracking.hasError) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      SessionStorageErrorBanner(
                        error: tracking.error!,
                        onRetry: () {
                          unawaited(
                            ref.read(sessionTrackingProvider.notifier).retry(),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    snapshot.when(
                      data: (TelemetrySnapshot data) =>
                          _DashboardData(snapshot: data),
                      loading: () => const _DashboardLoading(),
                      error: (Object error, StackTrace stackTrace) =>
                          _DashboardError(
                            error: error,
                            onRetry: () => ref
                                .read(telemetrySnapshotProvider.notifier)
                                .retry(),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const ChargingScreenSettingsCard(),
                    const SizedBox(height: AppSpacing.xl),
                    const _PrivacyNote(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (BuildContext context) => screen));
  }
}

/// Accent for the direction energy is flowing.
Color _flowColor(BatteryChargingState? state) => switch (state) {
  BatteryChargingState.charging || BatteryChargingState.full => AppColors.mint,
  BatteryChargingState.discharging => AppColors.sky,
  BatteryChargingState.notCharging => AppColors.warning,
  null => AppColors.textSecondary,
};

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
        ExcludeSemantics(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[AppColors.mintBright, AppColors.mint],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.mint.withValues(alpha: 0.35),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.background,
              size: 22,
            ),
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
                'Voltly',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
        ),
        _HeaderButton(
          icon: Icons.history_rounded,
          tooltip: 'Charging sessions',
          onPressed: onOpenHistory,
        ),
        const SizedBox(width: AppSpacing.xs),
        _HeaderButton(
          icon: Icons.tune_rounded,
          tooltip: 'Telemetry diagnostics',
          onPressed: onOpenDiagnostics,
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceElevated,
        side: const BorderSide(color: AppColors.outline),
      ),
      icon: Icon(icon, size: 20, color: AppColors.textPrimary),
    );
  }
}

class _DashboardData extends StatelessWidget {
  const _DashboardData({required this.snapshot});

  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return TelemetryFreshnessBuilder(
      observedAt: snapshot.observedAt,
      builder: (BuildContext context, bool isStale) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _LiveCurrentCard(snapshot: snapshot, isStale: isStale),
          if (isStale) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            const _StaleWarning(),
          ],
          const SizedBox(height: AppSpacing.sm),
          _BatteryCard(snapshot: snapshot),
          const SessionEstimateCard(),
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle('Details'),
          const SizedBox(height: AppSpacing.sm),
          _DetailGrid(snapshot: snapshot),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Readings come straight from Android. Power is calculated from '
            'voltage × current at the battery, not at the charger.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xxs),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// Hero readout: the live current, its trace and phase statistics.
class _LiveCurrentCard extends ConsumerWidget {
  const _LiveCurrentCard({required this.snapshot, required this.isStale});

  final TelemetrySnapshot snapshot;
  final bool isStale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LiveCurrentState live = ref.watch(liveCurrentProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TelemetryReading<BatteryChargingState> state = snapshot.chargingState;
    final TelemetryReading<BatteryPlugSource> plug = snapshot.plugSource;
    final TelemetryReading<double> current = snapshot.currentNow;
    final BatteryChargingState? stateValue = state.value;
    final Color accent = _flowColor(stateValue);
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    final String stateText = state.isAvailable
        ? formatTelemetryChargingState(state)
        : 'Charging state unavailable';

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.hero,
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(accent.withValues(alpha: 0.10), AppColors.surface),
            AppColors.surface,
            AppColors.background,
          ],
          stops: const <double>[0, 0.55, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Flexible(
                  child: Semantics(
                    container: true,
                    label: _chargingSemantics(state, plug),
                    child: ExcludeSemantics(
                      child: _StatusPill(
                        label: stateText,
                        color: accent,
                        pulsing: stateValue == BatteryChargingState.charging,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _LivePill(isStale: isStale),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              container: true,
              label:
                  'Current now, ${spokenMilliamps(current)}'
                  '${!current.isAvailable && current.reason != null ? '. ${current.reason}' : ''}',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('CURRENT NOW', style: AppTypography.eyebrow),
                    const SizedBox(height: AppSpacing.xs),
                    if (current.isAvailable)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: <Widget>[
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(end: current.value! * 1000),
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 450),
                              curve: Curves.easeOutCubic,
                              builder:
                                  (
                                    BuildContext context,
                                    double value,
                                    Widget? _,
                                  ) => Text(
                                    formatMilliampsValue(value, signed: true),
                                    style: AppTypography.heroNumber,
                                  ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'mA',
                              style: textTheme.titleLarge?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...<Widget>[
                      Text(
                        'Current unavailable',
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (current.reason != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(current.reason!, style: textTheme.bodySmall),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _flowCaption(state, plug),
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            if (current.isAvailable) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              CurrentSparkline(points: live.history, color: accent),
              const SizedBox(height: AppSpacing.md),
              _PhaseStats(
                live: live,
                onReset: () => ref.read(liveCurrentProvider.notifier).reset(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _flowCaption(
  TelemetryReading<BatteryChargingState> state,
  TelemetryReading<BatteryPlugSource> plug,
) {
  final BatteryPlugSource? source = plug.isAvailable ? plug.value : null;
  final String? via = switch (source) {
    BatteryPlugSource.ac => 'AC charger',
    BatteryPlugSource.usb => 'USB',
    BatteryPlugSource.wireless => 'wireless charger',
    BatteryPlugSource.dock => 'dock',
    BatteryPlugSource.none || null => null,
  };
  if (!state.isAvailable) {
    return via == null ? 'Power source unavailable' : 'Connected via $via';
  }
  return switch (state.value!) {
    BatteryChargingState.charging =>
      via == null ? 'Flowing into the battery' : 'Flowing in via $via',
    BatteryChargingState.full =>
      via == null ? 'Battery is full' : 'Full · connected via $via',
    BatteryChargingState.notCharging =>
      via == null ? 'Charging paused' : 'Paused · connected via $via',
    BatteryChargingState.discharging =>
      source == null || source == BatteryPlugSource.none
          ? 'Running on battery'
          : 'Drawing more than $via supplies',
  };
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.pulsing,
  });

  final String label;
  final Color color;
  final bool pulsing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ChargingPulse(
            active: pulsing,
            child: Icon(
              pulsing ? Icons.bolt_rounded : Icons.circle,
              size: pulsing ? 16 : 8,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.isStale});

  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final Color color = isStale ? AppColors.warning : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.outlineStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isStale ? AppColors.warning : AppColors.mint,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isStale ? 'Stale' : 'Live',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _PhaseStats extends StatelessWidget {
  const _PhaseStats({required this.live, required this.onReset});

  final LiveCurrentState live;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    String value(double? mA) =>
        live.hasStats && mA != null ? formatMilliampsValue(mA) : '—';
    final String phase = live.pluggedIn == false ? 'on battery' : 'plugged in';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xxs,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.45),
        borderRadius: AppRadius.tile,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              container: true,
              label: live.hasStats
                  ? 'Since $phase: minimum ${live.minMilliamps!.round()}, '
                        'average ${live.averageMilliamps!.round()}, '
                        'maximum ${live.maxMilliamps!.round()} milliamperes'
                  : 'Collecting current statistics',
              child: ExcludeSemantics(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _Stat(
                        label: 'Min',
                        value: value(live.minMilliamps),
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Avg',
                        value: value(live.averageMilliamps),
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Max',
                        value: value(live.maxMilliamps),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onReset,
            tooltip: 'Reset min and max',
            icon: const Icon(
              Icons.restart_alt_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label.toUpperCase(), style: AppTypography.eyebrow),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontFeatures: AppTypography.tabular),
          ),
        ),
      ],
    );
  }
}

/// Level ring plus the vitals people check most: source, health, temperature.
class _BatteryCard extends StatelessWidget {
  const _BatteryCard({required this.snapshot});

  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TelemetryReading<double> level = snapshot.batteryLevel;
    final double? levelValue = level.isAvailable ? level.value : null;
    final Color accent = _flowColor(snapshot.chargingState.value);

    final Widget ring = Semantics(
      container: true,
      label: levelValue != null
          ? 'Battery level ${levelValue.round()} percent'
          : 'Battery level unavailable',
      child: ExcludeSemantics(
        child: BatteryLevelRing(
          fraction: levelValue == null ? null : levelValue / 100,
          color: accent,
          child: levelValue != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatBatteryPercent(levelValue),
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text('LEVEL', style: AppTypography.eyebrow),
                  ],
                )
              : const Icon(
                  Icons.battery_unknown_rounded,
                  color: AppColors.textTertiary,
                ),
        ),
      ),
    );

    final Widget vitals = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Vital(
          label: 'Temperature',
          icon: Icons.device_thermostat_rounded,
          reading: snapshot.temperature,
          value: formatTelemetryNumeric(snapshot.temperature, 1, '°C'),
          spokenValue: spokenTelemetryNumeric(
            snapshot.temperature,
            1,
            'degrees Celsius',
          ),
          valueColor: _temperatureColor(snapshot.temperature),
        ),
        _Vital(
          label: 'Health',
          icon: Icons.favorite_rounded,
          reading: snapshot.health,
          value: formatTelemetryHealth(snapshot.health),
          spokenValue: snapshot.health.isAvailable
              ? formatTelemetryHealth(snapshot.health)
              : 'unavailable',
          valueColor: snapshot.health.value == BatteryHealth.good
              ? AppColors.mint
              : (snapshot.health.isAvailable ? AppColors.warning : null),
        ),
        _Vital(
          label: 'Source',
          icon: Icons.power_rounded,
          reading: snapshot.plugSource,
          value: snapshot.plugSource.value == BatteryPlugSource.none
              ? 'Battery'
              : formatTelemetryPlugSource(snapshot.plugSource),
          spokenValue: snapshot.plugSource.isAvailable
              ? formatTelemetryPlugSource(snapshot.plugSource)
              : 'unavailable',
          last: true,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  if (constraints.maxWidth < 300) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Center(child: ring),
                        const SizedBox(height: AppSpacing.md),
                        vitals,
                      ],
                    );
                  }
                  return Row(
                    children: <Widget>[
                      ring,
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: vitals),
                    ],
                  );
                },
              ),
              if (!level.isAvailable) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text('Battery level unavailable', style: textTheme.titleSmall),
                if (level.reason != null)
                  Text(level.reason!, style: textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Color? _temperatureColor(TelemetryReading<double> reading) {
  if (!reading.isAvailable) return null;
  final double c = reading.value!;
  if (c >= 45) return AppColors.danger;
  if (c >= 40) return AppColors.warning;
  return null;
}

class _Vital extends StatelessWidget {
  const _Vital({
    required this.label,
    required this.icon,
    required this.reading,
    required this.value,
    required this.spokenValue,
    this.valueColor,
    this.last = false,
  });

  final String label;
  final IconData icon;
  final TelemetryReading<Object> reading;
  final String value;
  final String spokenValue;
  final Color? valueColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool available = reading.isAvailable;
    return Semantics(
      container: true,
      label:
          '$label, $spokenValue'
          '${!available && reading.reason != null ? '. ${reading.reason}' : ''}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(bottom: BorderSide(color: AppColors.outline)),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) => Row(
              children: <Widget>[
                Icon(icon, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.55,
                  ),
                  child: Text(
                    available ? value : '—',
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: textTheme.titleMedium?.copyWith(
                      color: available
                          ? (valueColor ?? AppColors.textPrimary)
                          : AppColors.textTertiary,
                      fontFeatures: AppTypography.tabular,
                    ),
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

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.snapshot});

  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final TelemetryReading<double> power = calculateBatteryPower(snapshot);
    final List<Widget> tiles = <Widget>[
      _MetricTile(
        label: 'Voltage',
        icon: Icons.bolt_rounded,
        reading: snapshot.voltage,
        value: formatTelemetryNumeric(snapshot.voltage, 2, 'V'),
        spokenValue: spokenTelemetryNumeric(snapshot.voltage, 2, 'volts'),
      ),
      _MetricTile(
        label: 'Battery-side power',
        icon: Icons.speed_rounded,
        reading: power,
        value: formatTelemetryNumeric(power, 2, 'W'),
        spokenValue: spokenTelemetryNumeric(power, 2, 'watts'),
        semanticsSuffix:
            '. Approximate battery-side power, not charger input power.',
      ),
      _MetricTile(
        label: 'Average current',
        icon: Icons.ssid_chart_rounded,
        reading: snapshot.currentAverage,
        value: formatTelemetryMilliamps(snapshot.currentAverage),
        spokenValue: spokenMilliamps(snapshot.currentAverage),
      ),
      _MetricTile(
        label: 'Charge counter',
        icon: Icons.battery_std_rounded,
        reading: snapshot.chargeCounter,
        value: snapshot.chargeCounter.isAvailable
            ? '${groupThousands(snapshot.chargeCounter.value!.round())} mAh'
            : 'Unavailable',
        spokenValue: spokenTelemetryNumeric(
          snapshot.chargeCounter,
          0,
          'milliampere hours',
        ),
      ),
      _MetricTile(
        label: 'Technology',
        icon: Icons.science_rounded,
        reading: snapshot.technology,
        value: snapshot.technology.value ?? 'Unavailable',
        spokenValue: snapshot.technology.value ?? 'unavailable',
      ),
      _MetricTile(
        label: 'Charge cycles',
        icon: Icons.autorenew_rounded,
        reading: snapshot.cycleCount,
        value: formatTelemetryCycles(snapshot.cycleCount),
        spokenValue: snapshot.cycleCount.isAvailable
            ? '${snapshot.cycleCount.value!.round()}'
            : 'unavailable',
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 300 ? 2 : 1;
        final double width =
            (constraints.maxWidth - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final Widget tile in tiles)
              SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.icon,
    required this.reading,
    required this.value,
    required this.spokenValue,
    this.semanticsSuffix = '',
  });

  final String label;
  final IconData icon;
  final TelemetryReading<Object> reading;
  final String value;

  /// Screen-reader-friendly value, e.g. "4.20 volts".
  final String spokenValue;
  final String semanticsSuffix;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool available = reading.isAvailable;
    final bool calculated = reading.source == TelemetrySource.calculated;
    final String semanticsLabel =
        '$label, $spokenValue, '
        '${telemetryAvailabilityLabel(reading.availability)}, '
        '${telemetrySourceLabel(reading.source)}'
        '$semanticsSuffix'
        '${!available && reading.reason != null ? ' ${reading.reason}' : ''}';

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.tile,
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: available
                          ? AppColors.mintContainer
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      icon,
                      size: 17,
                      color: available
                          ? AppColors.mint
                          : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (calculated || !available)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: calculated
                              ? const TelemetryBadge(
                                  label: 'Calculated',
                                  color: AppColors.mint,
                                )
                              : TelemetryBadge(
                                  label: telemetryAvailabilityLabel(
                                    reading.availability,
                                  ),
                                  color: telemetryAvailabilityColor(
                                    reading.availability,
                                  ),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  available ? value : '—',
                  style: textTheme.titleLarge?.copyWith(
                    color: available
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: textTheme.bodySmall),
              if (!available && reading.reason != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  reading.reason!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StaleWarning extends StatelessWidget {
  const _StaleWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: AppRadius.tile,
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

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.hero,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: <Widget>[
          const SizedBox(
            width: 28,
            height: 28,
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
            'Measuring live current. Readings stay on this device.',
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.hero,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 28,
          ),
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
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(
          Icons.lock_outline_rounded,
          size: 14,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            'On-device only · No account · No tracking',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

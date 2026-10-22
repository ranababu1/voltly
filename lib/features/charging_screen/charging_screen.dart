import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/app/theme/app_tokens.dart';
import 'package:voltly/core/charging_screen/charging_screen_providers.dart';
import 'package:voltly/core/sessions/battery_time_estimate.dart';
import 'package:voltly/core/sessions/session_providers.dart';
import 'package:voltly/core/telemetry/battery_power.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';
import 'package:voltly/features/charging_screen/charging_ring.dart';
import 'package:voltly/features/charging_screen/charging_screen_presentation.dart';
import 'package:voltly/features/dashboard/telemetry_presentation.dart';

/// Minimal full-screen charging view: clock, animated level ring and four
/// metrics (temperature, current, estimate, battery-side power).
///
/// Shown over the lock screen when the charger trigger opens Voltly, or as a
/// preview from the dashboard. It closes itself when the charger is
/// unplugged. All values come from [telemetrySnapshotProvider] and the stored
/// session estimate; unavailable values are shown as a dash, never zero.
class ChargingScreen extends ConsumerStatefulWidget {
  const ChargingScreen({super.key, this.overLockScreen = false});

  /// Opened by the charger trigger and currently drawn over the keyguard.
  final bool overLockScreen;

  @override
  ConsumerState<ChargingScreen> createState() => _ChargingScreenState();
}

class _ChargingScreenState extends ConsumerState<ChargingScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  bool _seenPlugged = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _scheduleClockTick();
    ref.listenManual<AsyncValue<TelemetrySnapshot>>(telemetrySnapshotProvider, (
      AsyncValue<TelemetrySnapshot>? previous,
      AsyncValue<TelemetrySnapshot> next,
    ) {
      next.whenData(_observePlug);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  /// One timer per minute boundary rather than a per-second ticker.
  void _scheduleClockTick() {
    final DateTime now = DateTime.now();
    final DateTime nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _clockTimer = Timer(nextMinute.difference(now), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _scheduleClockTick();
    });
  }

  void _observePlug(TelemetrySnapshot snapshot) {
    final TelemetryReading<BatteryPlugSource> plug = snapshot.plugSource;
    if (!plug.isAvailable) return;
    if (plug.value != BatteryPlugSource.none) {
      _seenPlugged = true;
    } else if (_seenPlugged) {
      _close();
    }
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  Future<void> _openApp() async {
    if (widget.overLockScreen) {
      final bool unlocked = await ref
          .read(chargingScreenServiceProvider)
          .unlock();
      if (!unlocked || !mounted) return;
    }
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final TelemetrySnapshot? snapshot = ref
        .watch(telemetrySnapshotProvider)
        .value;
    final BatteryEstimateResult? estimate = ref
        .watch(activeSessionEstimateProvider)
        .value;
    final bool use24h = MediaQuery.alwaysUse24HourFormatOf(context);

    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop && widget.overLockScreen) {
          unawaited(
            ref.read(chargingScreenServiceProvider).releaseLockScreen(),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: AppSpacing.xl),
                _Clock(
                  time: formatChargingClock(_now, use24HourFormat: use24h),
                  date: formatChargingDate(_now),
                ),
                Expanded(
                  child: Center(
                    child: snapshot == null
                        ? const SizedBox.square(
                            dimension: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.mint,
                            ),
                          )
                        : _LevelGauge(snapshot: snapshot),
                  ),
                ),
                _MetricTiles(snapshot: snapshot, estimate: estimate),
                const SizedBox(height: AppSpacing.lg),
                _BottomBar(
                  power: snapshot == null
                      ? null
                      : calculateBatteryPower(snapshot),
                  onClose: _close,
                  onOpenApp: _openApp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Clock extends StatelessWidget {
  const _Clock({required this.time, required this.date});

  final String time;
  final String date;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$time, $date',
      child: ExcludeSemantics(
        child: Column(
          children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                time,
                style: textTheme.displayLarge?.copyWith(
                  fontSize: 88,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -3,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              date,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelGauge extends StatelessWidget {
  const _LevelGauge({required this.snapshot});

  final TelemetrySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TelemetryReading<double> level = snapshot.batteryLevel;
    final bool charging =
        snapshot.chargingState.value == BatteryChargingState.charging;
    final String status = chargingStatusLabel(snapshot.chargingState);

    return TelemetryFreshnessBuilder(
      observedAt: snapshot.observedAt,
      builder: (BuildContext context, bool isStale) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double size = [
            constraints.maxWidth * 0.82,
            constraints.maxHeight,
            340.0,
          ].reduce((double a, double b) => a < b ? a : b);
          final String levelText = level.isAvailable
              ? formatBatteryPercent(level.value!)
              : '—';

          return SizedBox.square(
            dimension: size,
            child: ChargingRing(
              levelPercent: level.value,
              animate: charging && !isStale,
              child: Semantics(
                container: true,
                label:
                    '${level.isAvailable ? 'Battery ${level.value!.round()} percent' : 'Battery level unavailable'}. '
                    '${status.toLowerCase()}${isStale ? '. Reading is stale' : ''}.',
                child: ExcludeSemantics(
                  child: Padding(
                    padding: EdgeInsets.all(size * 0.16),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ChargingPulse(
                            active: charging && !isStale,
                            child: Icon(
                              Icons.bolt_rounded,
                              size: 30,
                              color: charging
                                  ? AppColors.mint
                                  : AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            levelText,
                            style: textTheme.displayLarge?.copyWith(
                              fontSize: 64,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            status,
                            style: textTheme.labelLarge?.copyWith(
                              letterSpacing: 1.6,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (isStale) ...<Widget>[
                            const SizedBox(height: AppSpacing.xs),
                            TelemetryBadge(
                              label:
                                  'Stale · ${formatTelemetryTime(snapshot.observedAt)}',
                              color: AppColors.warning,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricTiles extends StatelessWidget {
  const _MetricTiles({required this.snapshot, required this.estimate});

  final TelemetrySnapshot? snapshot;
  final BatteryEstimateResult? estimate;

  @override
  Widget build(BuildContext context) {
    final TelemetrySnapshot? data = snapshot;
    final String? temperature = data == null
        ? null
        : formatTileTemperature(data.temperature);
    final String? current = data == null
        ? null
        : formatTileCurrent(data.currentNow);
    final String? remaining = formatTileEstimate(estimate);
    final String estimateLabel = estimateTileLabel(estimate);

    return Row(
      children: <Widget>[
        Expanded(
          child: _MetricTile(
            value: temperature,
            label: 'Temp',
            semanticsLabel: temperature == null
                ? 'Temperature unavailable'
                : 'Temperature $temperature',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricTile(
            value: current,
            label: 'Current',
            semanticsLabel: current == null
                ? 'Current unavailable'
                : 'Current $current, device reported',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MetricTile(
            value: remaining,
            label: estimateLabel,
            semanticsLabel: remaining == null
                ? 'Time estimate unavailable. '
                      '${estimate?.reason ?? 'Not enough stored samples yet.'}'
                : '$estimateLabel approximately $remaining, '
                      'calculated from stored samples',
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    required this.semanticsLabel,
  });

  final String? value;
  final String label;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool available = value != null;
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: AppColors.mint.withValues(alpha: available ? 0.55 : 0.2),
            ),
          ),
          child: Column(
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value ?? '—',
                  style: textTheme.titleLarge?.copyWith(
                    color: available
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: textTheme.labelMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.power,
    required this.onClose,
    required this.onOpenApp,
  });

  final TelemetryReading<double>? power;
  final VoidCallback onClose;
  final VoidCallback onOpenApp;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? watts = power == null ? null : formatTilePower(power!);

    return Row(
      children: <Widget>[
        _RoundButton(
          icon: Icons.close_rounded,
          tooltip: 'Close charging screen',
          onPressed: onClose,
        ),
        Expanded(
          child: Semantics(
            container: true,
            label: watts == null
                ? 'Battery power unavailable'
                : 'Approximately $watts battery-side power, calculated. '
                      'Not charger input power.',
            child: ExcludeSemantics(
              child: Column(
                children: <Widget>[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      watts == null ? '— W' : '≈ $watts',
                      style: textTheme.headlineMedium?.copyWith(
                        color: watts == null
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                  Text('battery-side', style: textTheme.labelSmall),
                ],
              ),
            ),
          ),
        ),
        _RoundButton(
          icon: Icons.open_in_new_rounded,
          tooltip: 'Open Voltly',
          onPressed: onOpenApp,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
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
      iconSize: 22,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.textSecondary,
        fixedSize: const Size.square(52),
        side: const BorderSide(color: AppColors.outline),
      ),
      icon: Icon(icon),
    );
  }
}

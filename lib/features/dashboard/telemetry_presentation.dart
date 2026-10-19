import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/app/theme/app_tokens.dart';
import 'package:voltly/core/errors/telemetry_exception.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// Shared formatting and presentation primitives for real telemetry.
///
/// These helpers never replace an unavailable reading with a number. Both the
/// dashboard and the developer diagnostics screen use them so status,
/// provenance and freshness language stay consistent.

String formatBatteryPercent(double value) => '${value.toStringAsFixed(0)}%';

String formatTelemetryBatteryLevel(TelemetryReading<double> reading) {
  if (!reading.isAvailable) return 'Unavailable';
  return formatBatteryPercent(reading.value!);
}

String formatTelemetryNumeric(
  TelemetryReading<double> reading,
  int decimals,
  String unit,
) {
  if (!reading.isAvailable) return 'Unavailable';
  return '${reading.value!.toStringAsFixed(decimals)} $unit';
}

String formatTelemetryChargingState(
  TelemetryReading<BatteryChargingState> reading,
) {
  if (!reading.isAvailable) return 'Unavailable';
  return switch (reading.value!) {
    BatteryChargingState.charging => 'Charging',
    BatteryChargingState.discharging => 'Discharging',
    BatteryChargingState.notCharging => 'Not charging',
    BatteryChargingState.full => 'Full',
  };
}

String formatTelemetryPlugSource(TelemetryReading<BatteryPlugSource> reading) {
  if (!reading.isAvailable) return 'Unavailable';
  return switch (reading.value!) {
    BatteryPlugSource.none => 'Not plugged in',
    BatteryPlugSource.ac => 'AC',
    BatteryPlugSource.usb => 'USB',
    BatteryPlugSource.wireless => 'Wireless',
    BatteryPlugSource.dock => 'Dock',
  };
}

String formatTelemetryTime(DateTime timestamp) {
  final DateTime local = timestamp.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}:'
      '${local.second.toString().padLeft(2, '0')}';
}

String formatTelemetryDateTime(DateTime timestamp) {
  final DateTime local = timestamp.toLocal();
  final String date =
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  return '$date ${formatTelemetryTime(local)}';
}

String telemetryAvailabilityLabel(TelemetryAvailability availability) =>
    switch (availability) {
      TelemetryAvailability.available => 'Available',
      TelemetryAvailability.unsupported => 'Unsupported',
      TelemetryAvailability.temporarilyUnavailable => 'Unavailable',
      TelemetryAvailability.invalid => 'Invalid',
      TelemetryAvailability.stale => 'Stale',
    };

Color telemetryAvailabilityColor(TelemetryAvailability availability) =>
    switch (availability) {
      TelemetryAvailability.available => AppColors.mint,
      TelemetryAvailability.unsupported => AppColors.textTertiary,
      TelemetryAvailability.temporarilyUnavailable => AppColors.warning,
      TelemetryAvailability.invalid => AppColors.danger,
      TelemetryAvailability.stale => AppColors.warning,
    };

String telemetrySourceLabel(TelemetrySource source) => switch (source) {
  TelemetrySource.device => 'Device',
  TelemetrySource.calculated => 'Calculated',
  TelemetrySource.estimated => 'Estimated',
};

Color telemetrySourceColor(TelemetrySource source) => switch (source) {
  TelemetrySource.device => AppColors.textSecondary,
  TelemetrySource.calculated => AppColors.mint,
  TelemetrySource.estimated => AppColors.warning,
};

String describeTelemetryError(Object error) {
  if (error is PlatformException) {
    final String? message = error.message;
    return message == null || message.isEmpty
        ? error.code
        : '${error.code}: $message';
  }
  if (error is TelemetryFormatException) return error.message;
  return 'Could not read battery telemetry.';
}

/// Compact status/provenance pill. Always includes a text label; color is
/// supplementary, never the only carrier of meaning.
class TelemetryBadge extends StatelessWidget {
  const TelemetryBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          letterSpacing: 0.2,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }
}

typedef TelemetryFreshnessWidgetBuilder = Widget Function(
  BuildContext context,
  bool isStale,
);

/// Rebuilds its child when a reading crosses the staleness threshold.
///
/// Uses a single one-shot timer rather than polling. The timer is cancelled
/// and rescheduled when the observation time changes, or on dispose.
class TelemetryFreshnessBuilder extends StatefulWidget {
  const TelemetryFreshnessBuilder({
    super.key,
    required this.observedAt,
    required this.builder,
  });

  final DateTime observedAt;
  final TelemetryFreshnessWidgetBuilder builder;

  @override
  State<TelemetryFreshnessBuilder> createState() =>
      _TelemetryFreshnessBuilderState();
}

class _TelemetryFreshnessBuilderState extends State<TelemetryFreshnessBuilder> {
  Timer? _staleTimer;

  @override
  void initState() {
    super.initState();
    _scheduleStaleUpdate();
  }

  @override
  void didUpdateWidget(covariant TelemetryFreshnessBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.observedAt != widget.observedAt) {
      _staleTimer?.cancel();
      _scheduleStaleUpdate();
    }
  }

  @override
  void dispose() {
    _staleTimer?.cancel();
    super.dispose();
  }

  void _scheduleStaleUpdate() {
    final Duration remaining = widget.observedAt
        .add(TelemetrySnapshot.staleAfter)
        .difference(DateTime.now());
    if (remaining <= Duration.zero) return;
    _staleTimer = Timer(remaining + const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {});
      if (!_isStale) _scheduleStaleUpdate();
    });
  }

  bool get _isStale =>
      DateTime.now().difference(widget.observedAt) >
      TelemetrySnapshot.staleAfter;

  @override
  Widget build(BuildContext context) => widget.builder(context, _isStale);
}

/// Convenience freshness pill for contexts that only need the status.
class TelemetryFreshnessBadge extends StatelessWidget {
  const TelemetryFreshnessBadge({super.key, required this.observedAt});

  final DateTime observedAt;

  @override
  Widget build(BuildContext context) {
    return TelemetryFreshnessBuilder(
      observedAt: observedAt,
      builder: (BuildContext context, bool isStale) => TelemetryBadge(
        label: isStale ? 'Stale' : 'Live',
        color: isStale ? AppColors.warning : AppColors.mint,
      ),
    );
  }
}

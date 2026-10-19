import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/app/theme/app_tokens.dart';
import 'package:voltly/core/errors/telemetry_exception.dart';
import 'package:voltly/core/telemetry/battery_power.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';

/// Developer-only view of the live native telemetry contract.
///
/// This is not the Phase 2 dashboard. It exists to validate real readings,
/// availability, provenance and timestamps on devices without inventing any
/// values. The provider is auto-disposed, so leaving this screen releases the
/// native broadcast receiver.
class TelemetryDiagnosticsScreen extends ConsumerWidget {
  const TelemetryDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TelemetrySnapshot> snapshot = ref.watch(
      telemetrySnapshotProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Telemetry diagnostics')),
      body: snapshot.when(
        data: (TelemetrySnapshot data) => _DiagnosticsBody(
          snapshot: data,
          onRefresh: () => ref.invalidate(telemetrySnapshotProvider),
        ),
        error: (Object error, StackTrace stackTrace) => _ErrorState(
          error: error,
          onRetry: () => ref.invalidate(telemetrySnapshotProvider),
        ),
        loading: () => const _LoadingState(),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Waiting for a battery reading…',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'The native adapter starts listening when this screen opens.',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Telemetry unavailable',
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _describeError(error),
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _describeError(Object error) {
  if (error is PlatformException) {
    final String? message = error.message;
    return message == null || message.isEmpty
        ? error.code
        : '${error.code}: $message';
  }
  if (error is TelemetryFormatException) return error.message;
  return 'Could not read battery telemetry.';
}

String _formatDateTime(DateTime timestamp) {
  final DateTime local = timestamp.toLocal();
  final String date =
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  return '$date ${_formatTime(local)}';
}

String _formatTime(DateTime timestamp) {
  final DateTime local = timestamp.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}:'
      '${local.second.toString().padLeft(2, '0')}';
}

class _DiagnosticsBody extends StatelessWidget {
  const _DiagnosticsBody({required this.snapshot, required this.onRefresh});

  final TelemetrySnapshot snapshot;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TelemetryReading<double> power = calculateBatteryPower(snapshot);

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SnapshotHeader(snapshot: snapshot),
            const SizedBox(height: AppSpacing.lg),
            _MetricGroup(
              title: 'Device readings',
              children: <Widget>[
                _ReadingRow(
                  label: 'Battery level',
                  reading: snapshot.batteryLevel,
                  value: _formatBatteryLevel(snapshot.batteryLevel),
                ),
                _ReadingRow(
                  label: 'Charging state',
                  reading: snapshot.chargingState,
                  value: _formatChargingState(snapshot.chargingState),
                ),
                _ReadingRow(
                  label: 'Power source',
                  reading: snapshot.plugSource,
                  value: _formatPlugSource(snapshot.plugSource),
                ),
                _ReadingRow(
                  label: 'Voltage',
                  reading: snapshot.voltage,
                  value: _formatNumeric(snapshot.voltage, 2, 'V'),
                ),
                _ReadingRow(
                  label: 'Temperature',
                  reading: snapshot.temperature,
                  value: _formatNumeric(snapshot.temperature, 1, '°C'),
                ),
                _ReadingRow(
                  label: 'Current now',
                  reading: snapshot.currentNow,
                  value: _formatNumeric(snapshot.currentNow, 3, 'A'),
                ),
                _ReadingRow(
                  label: 'Average current',
                  reading: snapshot.currentAverage,
                  value: _formatNumeric(snapshot.currentAverage, 3, 'A'),
                ),
                _ReadingRow(
                  label: 'Charge counter',
                  reading: snapshot.chargeCounter,
                  value: _formatNumeric(snapshot.chargeCounter, 1, 'mAh'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _PowerCard(power: power),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Contract v${snapshot.schemaVersion} · In-memory only · '
              'Nothing is stored or transmitted.',
              style: textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNumeric(
  TelemetryReading<double> reading,
  int decimals,
  String unit,
) {
  if (!reading.isAvailable) return 'Unavailable';
  return '${reading.value!.toStringAsFixed(decimals)} $unit';
}

String _formatBatteryLevel(TelemetryReading<double> reading) {
  if (!reading.isAvailable) return 'Unavailable';
  return '${reading.value!.toStringAsFixed(0)}%';
}

String _formatChargingState(TelemetryReading<BatteryChargingState> reading) {
  if (!reading.isAvailable) return 'Unavailable';
  return switch (reading.value!) {
    BatteryChargingState.charging => 'Charging',
    BatteryChargingState.discharging => 'Discharging',
    BatteryChargingState.notCharging => 'Not charging',
    BatteryChargingState.full => 'Full',
  };
}

String _formatPlugSource(TelemetryReading<BatteryPlugSource> reading) {
  if (!reading.isAvailable) return 'Unavailable';
  return switch (reading.value!) {
    BatteryPlugSource.none => 'Not plugged in',
    BatteryPlugSource.ac => 'AC',
    BatteryPlugSource.usb => 'USB',
    BatteryPlugSource.wireless => 'Wireless',
    BatteryPlugSource.dock => 'Dock',
  };
}

class _SnapshotHeader extends StatelessWidget {
  const _SnapshotHeader({required this.snapshot});

  final TelemetrySnapshot snapshot;

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
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.mintContainer,
                    borderRadius: AppRadius.control,
                  ),
                  child: const Icon(
                    Icons.developer_mode_rounded,
                    color: AppColors.mint,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Developer diagnostics',
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Real readings from Android. This screen validates the telemetry '
              'contract; it is not the final dashboard.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _Badge(
                  label: 'Schema v${snapshot.schemaVersion}',
                  color: AppColors.textSecondary,
                ),
                _FreshnessBadge(observedAt: snapshot.observedAt),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Observed ${_formatDateTime(snapshot.observedAt)}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Values are device-reported unless marked calculated. '
              'Unavailable values are never replaced with zero or a guess. '
              'A reading older than 5 minutes is marked stale.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _FreshnessBadge extends StatefulWidget {
  const _FreshnessBadge({required this.observedAt});

  final DateTime observedAt;

  @override
  State<_FreshnessBadge> createState() => _FreshnessBadgeState();
}

class _FreshnessBadgeState extends State<_FreshnessBadge> {
  Timer? _staleTimer;

  @override
  void initState() {
    super.initState();
    _scheduleStaleUpdate();
  }

  @override
  void didUpdateWidget(covariant _FreshnessBadge oldWidget) {
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
  Widget build(BuildContext context) {
    final bool stale = _isStale;
    return _Badge(
      label: stale ? 'Stale' : 'Live',
      color: stale ? AppColors.warning : AppColors.mint,
    );
  }
}

class _MetricGroup extends StatelessWidget {
  const _MetricGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int index = 0; index < children.length; index++) {
      if (index > 0) rows.add(const Divider());
      rows.add(children[index]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xxs,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(letterSpacing: 1.4, color: AppColors.textSecondary),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(children: rows),
          ),
        ),
      ],
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({
    required this.label,
    required this.reading,
    required this.value,
  });

  final String label;
  final TelemetryReading<Object> reading;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool available = reading.isAvailable;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: Text(label, style: textTheme.bodyLarge)),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    color: available
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _Badge(
                label: _availabilityLabel(reading.availability),
                color: _availabilityColor(reading.availability),
              ),
              _Badge(
                label: _sourceLabel(reading.source),
                color: _sourceColor(reading.source),
              ),
              Text(
                'Observed ${_formatTime(reading.observedAt)}',
                style: textTheme.bodySmall,
              ),
            ],
          ),
          if (!available && reading.reason != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xxs),
            Text(reading.reason!, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

String _availabilityLabel(TelemetryAvailability availability) =>
    switch (availability) {
      TelemetryAvailability.available => 'Available',
      TelemetryAvailability.unsupported => 'Unsupported',
      TelemetryAvailability.temporarilyUnavailable => 'Unavailable',
      TelemetryAvailability.invalid => 'Invalid',
      TelemetryAvailability.stale => 'Stale',
    };

Color _availabilityColor(TelemetryAvailability availability) =>
    switch (availability) {
      TelemetryAvailability.available => AppColors.mint,
      TelemetryAvailability.unsupported => AppColors.textTertiary,
      TelemetryAvailability.temporarilyUnavailable => AppColors.warning,
      TelemetryAvailability.invalid => AppColors.danger,
      TelemetryAvailability.stale => AppColors.warning,
    };

String _sourceLabel(TelemetrySource source) => switch (source) {
  TelemetrySource.device => 'Device',
  TelemetrySource.calculated => 'Calculated',
  TelemetrySource.estimated => 'Estimated',
};

Color _sourceColor(TelemetrySource source) => switch (source) {
  TelemetrySource.device => AppColors.textSecondary,
  TelemetrySource.calculated => AppColors.mint,
  TelemetrySource.estimated => AppColors.warning,
};

class _PowerCard extends StatelessWidget {
  const _PowerCard({required this.power});

  final TelemetryReading<double> power;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool available = power.isAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xxs,
            bottom: AppSpacing.xs,
          ),
          child: Text(
            'CALCULATED',
            style: textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Battery-side power',
                        style: textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        available
                            ? '${power.value!.toStringAsFixed(2)} W'
                            : 'Unavailable',
                        style: textTheme.titleMedium?.copyWith(
                          color: available
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _Badge(
                      label: _sourceLabel(power.source),
                      color: _sourceColor(power.source),
                    ),
                    _Badge(
                      label: _availabilityLabel(power.availability),
                      color: _availabilityColor(power.availability),
                    ),
                    Text(
                      'Observed ${_formatTime(power.observedAt)}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Approximate battery-side power from voltage × current. '
                  'Not wall-charger or adapter input power.',
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
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

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

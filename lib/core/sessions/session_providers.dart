import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/core/persistence/persistence_providers.dart';
import 'package:voltly/core/persistence/session_store.dart';
import 'package:voltly/core/sessions/battery_time_estimate.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/session_coordinator.dart';
import 'package:voltly/core/sessions/session_detail.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';

/// UI-facing state for live session persistence.
class SessionTrackingState {
  const SessionTrackingState({
    required this.initialized,
    this.activeSession,
    this.error,
    this.errorStackTrace,
  });

  const SessionTrackingState.initializing()
    : initialized = false,
      activeSession = null,
      error = null,
      errorStackTrace = null;

  const SessionTrackingState.ready(ChargingSession? active)
    : initialized = true,
      activeSession = active,
      error = null,
      errorStackTrace = null;

  const SessionTrackingState.failure(
    Object this.error,
    StackTrace this.errorStackTrace, {
    required this.initialized,
  }) : activeSession = null;

  final bool initialized;
  final ChargingSession? activeSession;
  final Object? error;
  final StackTrace? errorStackTrace;

  bool get hasError => error != null;
}

/// Owns the app's one session coordinator and feeds it foreground snapshots.
///
/// The database and coordinator are app-scoped. A storage failure pauses
/// tracking and is surfaced to the dashboard and history screen; Retry reloads
/// the committed active session instead of silently continuing.
class SessionTrackingController extends Notifier<SessionTrackingState> {
  late final SessionCoordinator _coordinator;
  bool _halted = false;

  @override
  SessionTrackingState build() {
    final SessionStore store = ref.watch(sessionRepositoryProvider);
    _coordinator = SessionCoordinator(store);

    ref.listen<AsyncValue<TelemetrySnapshot>>(telemetrySnapshotProvider, (
      AsyncValue<TelemetrySnapshot>? previous,
      AsyncValue<TelemetrySnapshot> next,
    ) {
      next.whenData((TelemetrySnapshot snapshot) {
        unawaited(_handleSnapshot(snapshot));
      });
    }, fireImmediately: true);
    unawaited(_initialize());
    return const SessionTrackingState.initializing();
  }

  Future<void> _initialize() async {
    try {
      final ChargingSession? active = await _coordinator.initialize();
      if (!ref.mounted) return;
      _halted = false;
      state = SessionTrackingState.ready(active);
      ref.invalidate(sessionHistoryProvider);
    } catch (error, stackTrace) {
      _fail(error, stackTrace, initialized: false);
    }
  }

  Future<void> _handleSnapshot(TelemetrySnapshot snapshot) async {
    if (_halted) return;
    try {
      final ChargingSession? active = await _coordinator.observe(snapshot);
      if (!ref.mounted) return;
      _halted = false;
      state = SessionTrackingState.ready(active);
      ref.invalidate(sessionHistoryProvider);
    } catch (error, stackTrace) {
      _fail(error, stackTrace, initialized: true);
    }
  }

  /// Retries storage initialization/recovery after a failure.
  Future<void> retry() async {
    _halted = false;
    state = const SessionTrackingState.initializing();
    try {
      final ChargingSession? active = await _coordinator.recover();
      if (!ref.mounted) return;
      state = SessionTrackingState.ready(active);
      ref.invalidate(sessionHistoryProvider);
    } catch (error, stackTrace) {
      _fail(error, stackTrace, initialized: false);
    }
  }

  void _fail(Object error, StackTrace stackTrace, {required bool initialized}) {
    if (!ref.mounted) return;
    _halted = true;
    state = SessionTrackingState.failure(
      error,
      stackTrace,
      initialized: initialized,
    );
    ref.invalidate(sessionHistoryProvider);
  }
}

final NotifierProvider<SessionTrackingController, SessionTrackingState>
sessionTrackingProvider =
    NotifierProvider<SessionTrackingController, SessionTrackingState>(
      SessionTrackingController.new,
    );

/// Recent sessions, refreshed after each committed session update.
final sessionHistoryProvider =
    FutureProvider.autoDispose<List<ChargingSession>>((Ref ref) {
      final SessionStore store = ref.watch(sessionRepositoryProvider);
      return store.recentSessions(limit: 50);
    });

/// One stored session and its retained samples.
final sessionDetailProvider = FutureProvider.autoDispose
    .family<SessionDetail?, int>((Ref ref, int sessionId) async {
      final SessionStore store = ref.watch(sessionRepositoryProvider);
      final ChargingSession? session = await store.sessionById(sessionId);
      if (session == null) return null;
      final List<TelemetrySample> samples = await store.samplesForSession(
        sessionId,
      );
      return SessionDetail(session: session, samples: samples);
    });

/// Estimate for the currently active session. Null when no session is active.
final activeSessionEstimateProvider =
    FutureProvider.autoDispose<BatteryEstimateResult?>((Ref ref) async {
      final SessionTrackingState tracking = ref.watch(sessionTrackingProvider);
      final int? sessionId = tracking.activeSession?.id;
      if (sessionId == null) return null;

      final SessionStore store = ref.watch(sessionRepositoryProvider);
      try {
        final ChargingSession? session = await store.sessionById(sessionId);
        if (session == null || !session.isActive) return null;
        final List<TelemetrySample> samples = await store.samplesForSession(
          sessionId,
        );
        final BatteryEstimateResult result = BatteryTimeEstimator.estimate(
          session: session,
          samples: samples,
        );
        if (result.isAvailable && samples.isNotEmpty) {
          final DateTime latestObservedAt = samples
              .map((TelemetrySample sample) => sample.observedAt)
              .reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b);
          final Duration untilStale = latestObservedAt
              .add(BatteryTimeEstimator.maximumSampleAge)
              .difference(DateTime.now());
          if (untilStale > Duration.zero) {
            final Timer timer = Timer(
              untilStale + const Duration(seconds: 1),
              () {
                if (ref.mounted) ref.invalidateSelf();
              },
            );
            ref.onDispose(timer.cancel);
          }
        }
        return result;
      } catch (error) {
        return BatteryEstimateResult.unavailable(
          'Stored session samples are unavailable (${error.runtimeType}).',
        );
      }
    });

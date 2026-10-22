import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/app/theme/app_theme.dart';
import 'package:voltly/core/charging_screen/charging_screen_providers.dart';
import 'package:voltly/core/charging_screen/charging_screen_service.dart';
import 'package:voltly/core/sessions/session_providers.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';
import 'package:voltly/features/charging_screen/charging_screen.dart';
import 'package:voltly/features/dashboard/dashboard_screen.dart';

/// Root widget for Voltly.
///
/// Owns the app lifecycle signal so telemetry acquisition pauses while the app
/// is not in the foreground. The last observation is retained by the provider.
class VoltlyApp extends ConsumerStatefulWidget {
  const VoltlyApp({super.key});

  @override
  ConsumerState<VoltlyApp> createState() => _VoltlyAppState();
}

class _VoltlyAppState extends ConsumerState<VoltlyApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<void>? _chargingLaunches;
  bool _chargingScreenVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final ChargingScreenService chargingScreen = ref.read(
      chargingScreenServiceProvider,
    );
    _chargingLaunches = chargingScreen.launchRequests.listen(
      (_) => _showChargingScreen(),
    );
    unawaited(
      chargingScreen.consumeLaunchRequest().then((bool launch) {
        if (launch) _showChargingScreen();
      }),
    );
    final AppLifecycleState? lifecycleState =
        WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null) {
      ref
          .read(appActiveProvider.notifier)
          .setActive(lifecycleState == AppLifecycleState.resumed);
    }
    // Start the app-scoped session coordinator immediately. It restores the
    // persisted active session before the first live snapshot is processed.
    ref.read(sessionTrackingProvider);
  }

  @override
  void dispose() {
    unawaited(_chargingLaunches?.cancel());
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Opens the lock-screen charging screen once, even if several triggers
  /// arrive while it is already visible.
  void _showChargingScreen() {
    if (!mounted || _chargingScreenVisible) return;
    final NavigatorState? navigator = _navigatorKey.currentState;
    if (navigator == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showChargingScreen(),
      );
      return;
    }
    _chargingScreenVisible = true;
    navigator
        .push(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (_, _, _) =>
                const ChargingScreen(overLockScreen: true),
            transitionsBuilder: (
              _,
              Animation<double> animation,
              _,
              Widget child,
            ) => FadeTransition(opacity: animation, child: child),
          ),
        )
        .whenComplete(() => _chargingScreenVisible = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(appActiveProvider.notifier)
        .setActive(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voltly',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      // Dark-only for the initial release; the palette is AMOLED-first.
      theme: AppTheme.dark,
      home: const DashboardScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voltly/app/theme/app_theme.dart';
import 'package:voltly/core/telemetry/telemetry_providers.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final AppLifecycleState? lifecycleState =
        WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null) {
      ref
          .read(appActiveProvider.notifier)
          .setActive(lifecycleState == AppLifecycleState.resumed);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      debugShowCheckedModeBanner: false,
      // Dark-only for the initial release; the palette is AMOLED-first.
      theme: AppTheme.dark,
      home: const DashboardScreen(),
    );
  }
}

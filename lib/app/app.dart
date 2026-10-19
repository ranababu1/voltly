import 'package:flutter/material.dart';

import 'package:voltly/app/theme/app_theme.dart';
import 'package:voltly/features/dashboard/dashboard_screen.dart';

/// Root widget for Voltly.
class VoltlyApp extends StatelessWidget {
  const VoltlyApp({super.key});

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

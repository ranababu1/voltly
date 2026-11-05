import 'package:flutter/material.dart';

/// Color tokens for Voltly.
///
/// The palette is AMOLED-first: true black is the canvas, cool graphite
/// surfaces establish hierarchy, mint marks energy flowing in (charging, live,
/// positive) and sky blue marks energy flowing out (on battery). Status colors
/// never carry meaning alone; pair them with text or icons.
abstract final class AppColors {
  // Surfaces.
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0B0E0D);
  static const Color surfaceElevated = Color(0xFF131817);
  static const Color surfaceHighlight = Color(0xFF1A2120);
  static const Color outline = Color(0xFF1E2725);
  static const Color outlineStrong = Color(0xFF2E3A37);

  // Brand: energy in.
  static const Color mint = Color(0xFF5CF0B0);
  static const Color mintBright = Color(0xFF9BFFD4);
  static const Color mintDeep = Color(0xFF0E5E41);
  static const Color mintContainer = Color(0xFF0D241B);

  // Energy out.
  static const Color sky = Color(0xFF7CC8FF);
  static const Color skyContainer = Color(0xFF0C1C2A);

  // Text.
  static const Color textPrimary = Color(0xFFF3F7F5);
  static const Color textSecondary = Color(0xFFA0ADA8);
  static const Color textTertiary = Color(0xFF6E7C77);

  // Status.
  static const Color warning = Color(0xFFF5BE6B);
  static const Color warningContainer = Color(0xFF2A1F0F);
  static const Color danger = Color(0xFFF2817C);
  static const Color dangerContainer = Color(0xFF351716);
}

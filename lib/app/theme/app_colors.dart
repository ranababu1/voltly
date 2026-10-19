import 'package:flutter/material.dart';

/// Color tokens for Voltly.
///
/// The palette is AMOLED-first: true black is the default background, dark
/// neutral-green surfaces establish hierarchy, and mint is reserved for
/// interactive, live and positive states. Status colors never carry meaning
/// alone; pair them with text or icons.
abstract final class AppColors {
  // Surfaces.
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0B100E);
  static const Color surfaceElevated = Color(0xFF121A16);
  static const Color outline = Color(0xFF24312A);
  static const Color outlineStrong = Color(0xFF34453C);

  // Brand.
  static const Color mint = Color(0xFF55E6A5);
  static const Color mintDeep = Color(0xFF0E5E41);
  static const Color mintContainer = Color(0xFF0F2A20);

  // Text.
  static const Color textPrimary = Color(0xFFF2F7F4);
  static const Color textSecondary = Color(0xFF9DACA4);
  static const Color textTertiary = Color(0xFF74847C);

  // Status.
  static const Color warning = Color(0xFFF2B45E);
  static const Color warningContainer = Color(0xFF2A1F0F);
  static const Color danger = Color(0xFFF27A75);
  static const Color dangerContainer = Color(0xFF351716);
}

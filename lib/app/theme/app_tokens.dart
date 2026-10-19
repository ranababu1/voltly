import 'package:flutter/widgets.dart';

/// Spacing scale, in logical pixels.
///
/// Use these tokens instead of ad-hoc values so layouts stay consistent and
/// adapt predictably to text scaling.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Corner radii used across Voltly.
abstract final class AppRadius {
  static const double sm = 12;
  static const double lg = 24;
  static const double full = 999;

  static const BorderRadius control = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(full));
}

import 'package:flutter/material.dart';

import 'package:voltly/app/theme/app_colors.dart';

/// Typography scale for Voltly.
///
/// Voltly uses the platform's default sans-serif so the app stays
/// offline-first and ships no font assets before brand type is finalized.
/// Sizes and line heights are tuned for dense telemetry without sacrificing
/// legibility when the system text scale is increased.
abstract final class AppTypography {
  /// Fixed-width digits so live values do not jitter as they update.
  static const List<FontFeature> tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// Hero numeral for the live current readout.
  static const TextStyle heroNumber = TextStyle(
    fontSize: 64,
    height: 1,
    fontWeight: FontWeight.w300,
    letterSpacing: -2.5,
    color: AppColors.textPrimary,
    fontFeatures: tabular,
  );

  /// Eyebrow label above a value, e.g. "CURRENT".
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
    color: AppColors.textTertiary,
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 56,
      height: 1,
      fontWeight: FontWeight.w300,
      letterSpacing: -2.2,
      color: AppColors.textPrimary,
      fontFeatures: tabular,
    ),
    displaySmall: TextStyle(
      fontSize: 40,
      height: 1.1,
      fontWeight: FontWeight.w600,
      letterSpacing: -1.2,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
      color: AppColors.textPrimary,
      fontFeatures: tabular,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.25,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: AppColors.textPrimary,
      fontFeatures: tabular,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.55,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      height: 1.5,
      fontWeight: FontWeight.w400,
      color: AppColors.textTertiary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 1.2,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: AppColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
      color: AppColors.textSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      height: 1.2,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.6,
      color: AppColors.textTertiary,
    ),
  );
}

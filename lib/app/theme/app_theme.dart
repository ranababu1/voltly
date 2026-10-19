import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/app/theme/app_tokens.dart';
import 'package:voltly/app/theme/app_typography.dart';

/// Theme definition for Voltly.
///
/// The initial release is dark-only by design: true black surfaces suit OLED
/// displays and keep the mint accent as the single focus color.
abstract final class AppTheme {
  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.mint,
    onPrimary: AppColors.background,
    primaryContainer: AppColors.mintContainer,
    onPrimaryContainer: AppColors.mint,
    secondary: AppColors.mint,
    onSecondary: AppColors.background,
    secondaryContainer: AppColors.mintContainer,
    onSecondaryContainer: AppColors.mint,
    tertiary: AppColors.warning,
    onTertiary: AppColors.background,
    tertiaryContainer: AppColors.warningContainer,
    onTertiaryContainer: AppColors.warning,
    error: AppColors.danger,
    onError: AppColors.background,
    errorContainer: AppColors.dangerContainer,
    onErrorContainer: AppColors.danger,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceDim: AppColors.background,
    surfaceBright: AppColors.surfaceElevated,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceElevated,
    surfaceContainerHighest: AppColors.surfaceElevated,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.outline,
    outlineVariant: AppColors.outline,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.background,
    inversePrimary: AppColors.mintDeep,
    surfaceTint: Colors.transparent,
  );

  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData get dark {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: AppTypography.textTheme,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: overlayStyle,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: AppColors.outline),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.mint,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}

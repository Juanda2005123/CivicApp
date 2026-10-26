import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Light and dark themes of the "Sello comunitario" design system.
///
/// Everything visual comes from here: widgets read [ColorScheme],
/// [TextTheme], [AppSemanticColors] and the component themes, never hex values.
abstract final class AppTheme {
  static final ThemeData light = _build(_lightScheme, AppSemanticColors.light);
  static final ThemeData dark = _build(_darkScheme, AppSemanticColors.dark);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.ink,
    onPrimary: AppColors.cream,
    secondary: AppColors.clay700,
    onSecondary: Colors.white,
    tertiary: AppColors.mustard,
    onTertiary: AppColors.ink,
    error: AppColors.errorLight,
    onError: Colors.white,
    errorContainer: AppColors.errorContainerLight,
    onErrorContainer: AppColors.errorLight,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.graphite,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: AppColors.paper,
    surfaceContainer: AppColors.paper,
    surfaceContainerHigh: AppColors.paper,
    surfaceContainerHighest: Colors.white,
    outline: AppColors.outlineLight,
    outlineVariant: AppColors.dividerLight,
    inverseSurface: AppColors.ink,
    onInverseSurface: AppColors.cream,
    inversePrimary: AppColors.mustard,
    shadow: AppColors.ink,
    scrim: AppColors.ink,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.mustard,
    onPrimary: AppColors.inkDeep,
    secondary: AppColors.clay300,
    onSecondary: AppColors.inkDeep,
    tertiary: AppColors.mustard,
    onTertiary: AppColors.inkDeep,
    error: AppColors.errorDark,
    onError: AppColors.inkDeep,
    errorContainer: AppColors.errorContainerDark,
    onErrorContainer: AppColors.errorDark,
    surface: AppColors.inkDeep,
    onSurface: AppColors.cream,
    onSurfaceVariant: AppColors.onSurfaceVariantDark,
    surfaceContainerLowest: AppColors.inkDeep,
    surfaceContainerLow: AppColors.ink,
    surfaceContainer: AppColors.ink,
    surfaceContainerHigh: AppColors.inkRaised,
    surfaceContainerHighest: AppColors.inkRaised,
    outline: AppColors.outlineDark,
    outlineVariant: AppColors.inkLine,
    inverseSurface: AppColors.inkRaised,
    onInverseSurface: AppColors.cream,
    inversePrimary: AppColors.mustard,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  static ThemeData _build(ColorScheme scheme, AppSemanticColors semantic) {
    final textTheme = AppTextStyles.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final isLight = scheme.brightness == Brightness.light;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: AppRadii.small,
          borderSide: BorderSide(color: color, width: width),
        );

    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadii.small);
    const buttonMinimum = Size(64, AppSizes.button);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surfaceContainerLow,
      textTheme: textTheme,
      extensions: [semantic],
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinimum,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.45),
          disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.9),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinimum,
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.onSurface, width: 1.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget - 4),
          foregroundColor: scheme.secondary,
          textStyle: textTheme.labelLarge?.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: scheme.secondary,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.touchTarget),
          foregroundColor: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        hintStyle: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        border: border(scheme.outline, 1.5),
        enabledBorder: border(scheme.outline, 1.5),
        focusedBorder: border(semantic.accent, 2),
        errorBorder: border(scheme.error, 2),
        focusedErrorBorder: border(scheme.error, 2),
        disabledBorder: border(scheme.outline.withValues(alpha: 0.55), 1.5),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.medium,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.small),
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isLight ? scheme.primary : semantic.accent,
        linearTrackColor: scheme.outlineVariant,
      ),
      listTileTheme: ListTileThemeData(iconColor: semantic.accent),
      visualDensity: VisualDensity.standard,
    );
  }
}

import 'package:flutter/material.dart';

/// Brand colors of the "Sello comunitario" design system
/// (docs/design/03-design-system.md, section 3). Widgets never use these
/// constants for text or surfaces: they read the [ColorScheme] and
/// [AppSemanticColors] of the active theme. The constants are for the theme
/// itself and for the brand painters (seal, rank seals), which look the same
/// in both themes.
abstract final class AppColors {
  // Brand
  static const Color ink = Color(0xFF10364A);
  static const Color inkDeep = Color(0xFF0B2433);
  static const Color inkRaised = Color(0xFF17455C);
  static const Color inkLine = Color(0xFF26516A);
  static const Color cream = Color(0xFFF6EFE0);
  static const Color paper = Color(0xFFFFFBF2);
  static const Color clay500 = Color(0xFFCF5C3F);
  static const Color clay700 = Color(0xFFA8432A);
  static const Color clay300 = Color(0xFFEE8C6E);
  static const Color mustard = Color(0xFFE8B03A);
  static const Color sage700 = Color(0xFF4F7A5A);
  static const Color graphite = Color(0xFF55606B);

  // Light neutrals
  static const Color outlineLight = Color(0xFF7A6F5C);
  static const Color dividerLight = Color(0xFFD9CFBB);

  // Dark neutrals
  static const Color onSurfaceVariantDark = Color(0xFFB8C4C9);
  static const Color outlineDark = Color(0xFF6F8F9E);

  // States, light
  static const Color successLight = Color(0xFF1F6B4A);
  static const Color successContainerLight = Color(0xFFE3EFE3);
  static const Color errorLight = Color(0xFFA3261B);
  static const Color errorContainerLight = Color(0xFFF8E3DE);
  static const Color infoLight = Color(0xFF1F5F85);
  static const Color infoContainerLight = Color(0xFFE0ECF2);
  static const Color warningLight = Color(0xFF8A5A00);
  static const Color warningContainerLight = Color(0xFFF8ECCB);

  // States, dark
  static const Color successDark = Color(0xFF6FCB9F);
  static const Color successContainerDark = Color(0xFF123F36);
  static const Color errorDark = Color(0xFFFF9C8F);
  static const Color errorContainerDark = Color(0xFF4A2026);
  static const Color infoDark = Color(0xFF8CC3E3);
  static const Color infoContainerDark = inkRaised;
  static const Color warningDark = Color(0xFFF2C66A);
  static const Color warningContainerDark = Color(0xFF4A3A12);
}

/// Colors that [ColorScheme] has no slot for. Read them with `context.semantic`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color accent;
  final Color success;
  final Color successContainer;
  final Color info;
  final Color infoContainer;
  final Color warning;
  final Color warningContainer;

  const AppSemanticColors({
    required this.accent,
    required this.success,
    required this.successContainer,
    required this.info,
    required this.infoContainer,
    required this.warning,
    required this.warningContainer,
  });

  static const light = AppSemanticColors(
    accent: AppColors.clay700,
    success: AppColors.successLight,
    successContainer: AppColors.successContainerLight,
    info: AppColors.infoLight,
    infoContainer: AppColors.infoContainerLight,
    warning: AppColors.warningLight,
    warningContainer: AppColors.warningContainerLight,
  );

  static const dark = AppSemanticColors(
    accent: AppColors.mustard,
    success: AppColors.successDark,
    successContainer: AppColors.successContainerDark,
    info: AppColors.infoDark,
    infoContainer: AppColors.infoContainerDark,
    warning: AppColors.warningDark,
    warningContainer: AppColors.warningContainerDark,
  );

  @override
  AppSemanticColors copyWith({
    Color? accent,
    Color? success,
    Color? successContainer,
    Color? info,
    Color? infoContainer,
    Color? warning,
    Color? warningContainer,
  }) {
    return AppSemanticColors(
      accent: accent ?? this.accent,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  /// The semantic colors of the active theme.
  AppSemanticColors get semantic => Theme.of(this).extension<AppSemanticColors>()!;
}

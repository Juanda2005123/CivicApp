import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Severity colors (docs/design/03-design-system.md, section 3.3). Color is
/// never the only signal: every level also has a shape and a text label.
/// Read them with `context.severity`.
@immutable
class AppSeverityColors extends ThemeExtension<AppSeverityColors> {
  final Color low;
  final Color medium;
  final Color high;
  final Color critical;

  /// Text and icons drawn on top of each severity color.
  final Color onLow;
  final Color onMedium;
  final Color onHigh;
  final Color onCritical;

  /// Outline that keeps a marker visible on the map tiles.
  final Color markerOutline;

  const AppSeverityColors({
    required this.low,
    required this.medium,
    required this.high,
    required this.critical,
    required this.onLow,
    required this.onMedium,
    required this.onHigh,
    required this.onCritical,
    required this.markerOutline,
  });

  static const light = AppSeverityColors(
    low: AppColors.severityLowLight,
    medium: AppColors.mustard,
    high: AppColors.severityHighLight,
    critical: AppColors.severityCriticalLight,
    onLow: Colors.white,
    onMedium: AppColors.ink,
    onHigh: Colors.white,
    onCritical: Colors.white,
    markerOutline: AppColors.ink,
  );

  static const dark = AppSeverityColors(
    low: AppColors.severityLowDark,
    medium: AppColors.mustard,
    high: AppColors.severityHighDark,
    critical: AppColors.severityCriticalDark,
    onLow: AppColors.inkDeep,
    onMedium: AppColors.inkDeep,
    onHigh: AppColors.inkDeep,
    onCritical: AppColors.inkDeep,
    markerOutline: AppColors.inkDeep,
  );

  @override
  AppSeverityColors copyWith({
    Color? low,
    Color? medium,
    Color? high,
    Color? critical,
    Color? onLow,
    Color? onMedium,
    Color? onHigh,
    Color? onCritical,
    Color? markerOutline,
  }) {
    return AppSeverityColors(
      low: low ?? this.low,
      medium: medium ?? this.medium,
      high: high ?? this.high,
      critical: critical ?? this.critical,
      onLow: onLow ?? this.onLow,
      onMedium: onMedium ?? this.onMedium,
      onHigh: onHigh ?? this.onHigh,
      onCritical: onCritical ?? this.onCritical,
      markerOutline: markerOutline ?? this.markerOutline,
    );
  }

  @override
  AppSeverityColors lerp(ThemeExtension<AppSeverityColors>? other, double t) {
    if (other is! AppSeverityColors) return this;
    return AppSeverityColors(
      low: Color.lerp(low, other.low, t)!,
      medium: Color.lerp(medium, other.medium, t)!,
      high: Color.lerp(high, other.high, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      onLow: Color.lerp(onLow, other.onLow, t)!,
      onMedium: Color.lerp(onMedium, other.onMedium, t)!,
      onHigh: Color.lerp(onHigh, other.onHigh, t)!,
      onCritical: Color.lerp(onCritical, other.onCritical, t)!,
      markerOutline: Color.lerp(markerOutline, other.markerOutline, t)!,
    );
  }
}

extension AppSeverityContext on BuildContext {
  /// The severity colors of the active theme.
  AppSeverityColors get severity => Theme.of(this).extension<AppSeverityColors>()!;
}

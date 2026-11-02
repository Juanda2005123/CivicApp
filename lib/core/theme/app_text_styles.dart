import 'package:flutter/material.dart';

/// Typography of the design system, section 4.
///
/// Fraunces and IBM Plex Sans are variable fonts bundled in `assets/fonts/`:
/// the weight is set through `FontVariation('wght', ...)`. `fontWeight` is
/// left unset on purpose, otherwise the engine would add a synthetic bold.
abstract final class AppTextStyles {
  static const String _display = 'Fraunces';
  static const String _sans = 'IBMPlexSans';
  static const String _mono = 'IBMPlexMono';

  static TextStyle _fraunces(double size, double line, double weight, {double tracking = 0}) {
    return TextStyle(
      fontFamily: _display,
      fontSize: size,
      height: line / size,
      letterSpacing: tracking * size,
      fontVariations: [
        FontVariation('wght', weight),
        FontVariation('opsz', size.clamp(9, 144).toDouble()),
      ],
    );
  }

  static TextStyle _plex(double size, double line, double weight, {double tracking = 0}) {
    return TextStyle(
      fontFamily: _sans,
      fontSize: size,
      height: line / size,
      letterSpacing: tracking * size,
      fontVariations: [FontVariation('wght', weight)],
    );
  }

  // Roles (sizes and line heights in logical pixels)
  static final TextStyle display = _fraunces(32, 40, 700, tracking: 0.02);
  static final TextStyle headline = _fraunces(24, 32, 600);
  static final TextStyle title = _plex(18, 26, 600);
  static final TextStyle body = _plex(16, 24, 400);
  static final TextStyle bodyStrong = _plex(16, 24, 600);
  static final TextStyle bodySmall = _plex(14, 20, 400);
  static final TextStyle label = _plex(14, 20, 600, tracking: 0.01);
  static final TextStyle fieldLabel = _plex(14, 20, 500);
  static final TextStyle caption = _plex(12, 16, 400);

  /// Fraunces 600 at 20 for app bars.
  static final TextStyle appBarTitle = _fraunces(20, 28, 600);

  /// Wordmark: "VIGÍA" in Fraunces 700 with 0.06 em of tracking.
  static TextStyle wordmark(double size) => _fraunces(size, size * 1.15, 700, tracking: 0.06);

  /// Registry data (codes, coordinates, dates, points): IBM Plex Mono 500.
  static TextStyle data({double size = 14, double line = 20}) {
    return TextStyle(fontFamily: _mono, fontSize: size, height: line / size);
  }

  /// Fraunces numeral for rank seals.
  static TextStyle numeral(double size) => _fraunces(size, size, 700);

  /// Material text roles mapped to the system's styles (design document 4).
  static TextTheme get textTheme => TextTheme(
        displaySmall: display,
        headlineSmall: headline,
        titleLarge: appBarTitle,
        titleMedium: title,
        bodyLarge: body,
        bodyMedium: bodySmall,
        bodySmall: caption,
        labelLarge: label,
        labelMedium: fieldLabel,
        labelSmall: caption,
      );
}

import 'package:flutter/material.dart';

/// Spacing scale (base 4/8) of the design system, section 5.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal margin of a screen.
  static const double screen = 20;

  /// Vertical gap between form fields.
  static const double field = 14;

  /// Widest a form or card gets on large screens (web, tablets).
  static const double maxContentWidth = 440;
}

abstract final class AppRadii {
  static const double sm = 8; // buttons, fields, notices
  static const double md = 12; // cards
  static const double lg = 16; // bottom sheets
  static const double chip = 14;

  static BorderRadius get small => BorderRadius.circular(sm);
  static BorderRadius get medium => BorderRadius.circular(md);
  static BorderRadius get large => BorderRadius.circular(lg);
}

/// Component dimensions (dp).
abstract final class AppSizes {
  static const double button = 52;
  static const double buttonCompact = 40;
  static const double field = 52;
  static const double chip = 28;
  static const double touchTarget = 48;
  static const double icon = 20;
  static const double iconLarge = 24;
}

/// Durations and curve of the design system, section 5.
abstract final class AppMotion {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration emphasized = Duration(milliseconds: 320);
  static const Duration reduced = Duration(milliseconds: 100);

  /// `cubic-bezier(.2, 0, 0, 1)`
  static const Curve curve = Cubic(0.2, 0, 0, 1);

  /// True when the system asks to reduce motion: no scale or rotation, fades only.
  static bool reduceOf(BuildContext context) => MediaQuery.disableAnimationsOf(context);
}

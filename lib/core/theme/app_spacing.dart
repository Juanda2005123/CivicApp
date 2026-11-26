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

  /// Maximum height of the list of a searchable dropdown.
  static const double dropdownMenuHeight = 280;

  /// Height of the Step 1 map that picks the report point (HU-27) when the
  /// screen is too short for it to fill the step.
  static const double mapPicker = 360;

  /// Size of the fixed pin at the center of that map.
  static const double mapPin = 44;

  // City identity (docs/design/04-city-identity.md).

  /// City header with its photo, and its short version on the login.
  static const double cityHero = 240;
  static const double cityHeroCompact = 168;

  /// Photo card of a city (registration) and thumbnail of a city (switcher).
  static const double cityCard = 88;
  static const double cityThumbnail = 48;

  /// Flag stripe: the small one over a photo and the one under the seal.
  static const double flagWidth = 32;
  static const double flagHeight = 8;
  static const double flagWide = 160;

  /// Round photo of a step of the rank climb, and its dotted path.
  static const double medal = 56;
  static const double trailDot = 3;

  /// Seal of the validation celebration and its ring.
  static const double celebrationSeal = 160;

  /// Pill behind the active icon of the bottom bar.
  static const double navPillWidth = 56;
  static const double navPillHeight = 30;

  /// Placeholder lines, thumbnail and photo of the loading skeletons.
  static const double skeletonLine = 14;
  static const double skeletonThumbnail = 64;
  static const double skeletonPhoto = 180;

  /// Dotted ring around the thumb of "Apoyar".
  static const double endorseRing = 34;

  /// Width of the decoded photos (`cacheWidth`), from the source sizes.
  static const int heroCacheWidth = 1080;
  static const int cardCacheWidth = 720;
  static const int rankCacheWidth = 480;
  static const int medalCacheWidth = 192;
}

/// Durations and curve of the design system, section 5.
abstract final class AppMotion {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration emphasized = Duration(milliseconds: 320);
  static const Duration reduced = Duration(milliseconds: 100);

  /// A photo opening over the screen (4C).
  static const Duration reveal = Duration(milliseconds: 600);

  /// Shortest fall of a piece of confetti (3A).
  static const Duration celebration = Duration(milliseconds: 1400);

  /// One way of the slow zoom of the city header (6A).
  static const Duration ambient = Duration(seconds: 20);

  /// `cubic-bezier(.2, 0, 0, 1)`
  static const Curve curve = Cubic(0.2, 0, 0, 1);

  /// `cubic-bezier(.3, 1.4, .5, 1)`: lands with a small bounce, like a stamp.
  static const Curve curveStamp = Cubic(0.3, 1.4, 0.5, 1);

  /// 2D, endorsing: the thumb jumps, "+1" floats up and the ring beats.
  static const Duration thumbJump = Duration(milliseconds: 380);
  static const Duration floatUp = Duration(milliseconds: 750);
  static const Duration ringBeat = Duration(milliseconds: 420);

  /// 3A, validated report: the seal drops and a wave leaves it.
  static const Duration stampDrop = Duration(milliseconds: 520);
  static const Duration shockwave = Duration(milliseconds: 700);

  /// How long the celebrations stay unless the citizen taps them.
  static const Duration validationHold = Duration(milliseconds: 2500);
  static const Duration rankHold = Duration(milliseconds: 2600);

  /// 7A, changing city: the flag sweeps in and then leaves.
  static const Duration curtainIn = Duration(milliseconds: 300);
  static const Duration curtainOut = Duration(milliseconds: 380);

  /// 8D: nothing is shown for work shorter than this.
  static const Duration loadingDelay = Duration(milliseconds: 300);

  /// One pass of the shine over a skeleton (8D).
  static const Duration shimmer = Duration(milliseconds: 1100);

  /// True when the system asks to reduce motion: no scale or rotation, fades only.
  static bool reduceOf(BuildContext context) => MediaQuery.disableAnimationsOf(context);
}

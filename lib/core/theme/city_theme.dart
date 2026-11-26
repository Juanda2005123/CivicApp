import 'package:flutter/material.dart';

import '../../features/city_identity/domain/entities/city_identity.dart';
import '../../features/city_identity/domain/entities/city_palette.dart';
import '../../features/city_identity/domain/entities/day_part.dart';
import '../utils/search_text.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// One stripe of the city flag, top to bottom.
@immutable
class CityFlagBand {
  final Color color;
  final int weight;

  const CityFlagBand(this.color, this.weight);

  @override
  bool operator ==(Object other) => other is CityFlagBand && other.color == color && other.weight == weight;

  @override
  int get hashCode => Object.hash(color, weight);
}

/// The place of one civic rank, ready to be drawn.
@immutable
class CityLandmark {
  /// The rank it stands for (`civic_rank.name`).
  final String rankName;

  /// The place ("La Ermita"), or the rank name in the looks without photos.
  final String title;

  /// Photo decoded for the round medals; null without photos.
  final ImageProvider? medal;

  /// The same photo at full size, for the rank celebration.
  final ImageProvider? photo;
  final String? photoDescription;

  const CityLandmark({
    required this.rankName,
    required this.title,
    this.medal,
    this.photo,
    this.photoDescription,
  });
}

/// A city with its own pack, as the registration cards and the city switcher
/// show it.
@immutable
class CityShowcase {
  final String name;
  final String department;
  final ImageProvider? card;
  final ImageProvider? thumbnail;
  final Color veil;
  final List<CityFlagBand> flag;

  const CityShowcase({
    required this.name,
    required this.department,
    required this.veil,
    this.card,
    this.thumbnail,
    this.flag = const [],
  });
}

/// What the city says.
@immutable
class CityThemeCopy {
  final String greeting;
  final String slogan;
  final String validationCheer;
  final String climbTitle;

  const CityThemeCopy({
    required this.greeting,
    required this.slogan,
    required this.validationCheer,
    required this.climbTitle,
  });
}

/// The look of the active city, inside the theme: what the [ColorScheme] has no
/// slot for (photo, flag, places, words). Widgets read `CityTheme.of(context)`
/// and **never** ask which city it is: whatever differs between cities arrives
/// here as data (docs/design/04-city-identity.md, section 3.1).
@immutable
class CityTheme extends ThemeExtension<CityTheme> {
  /// Text and icons over a photo or the veil: white in every city, which every
  /// veil passes AA against (checked by the contrast test).
  static const Color onVeil = Colors.white;

  final String slug;

  /// City and department being shown; empty before any city is known.
  final String displayName;
  final String department;
  final CityIdentityLevel level;
  final DayPart dayPart;

  /// Header photo of the moment of the day; null in the looks without photos.
  final ImageProvider? hero;
  final String? heroDescription;

  final List<CityFlagBand> flag;

  /// Warm tone: main buttons, "Reportar", "TÚ", the endorsement bar, confetti.
  final Color accent;
  final Color onAccent;

  /// Tone that reads on the surfaces of this brightness (links, active chips,
  /// highlighted icons): the deep tone on light, the accent on dark.
  final Color deep;
  final Color onDeep;

  /// Dark layer over the photos so white text passes AA.
  final Color veil;

  /// Bottom bar: color of the active tab and the pill behind its icon.
  final Color navSelected;
  final Color navPill;

  /// The four rank places of the citizen's own city, lowest rank first.
  final List<CityLandmark> landmarks;

  final CityThemeCopy copy;

  /// The cities with their own pack.
  final List<CityShowcase> showcase;

  const CityTheme({
    required this.slug,
    required this.displayName,
    required this.department,
    required this.level,
    required this.dayPart,
    required this.hero,
    required this.heroDescription,
    required this.flag,
    required this.accent,
    required this.onAccent,
    required this.deep,
    required this.onDeep,
    required this.veil,
    required this.navSelected,
    required this.navPill,
    required this.landmarks,
    required this.copy,
    required this.showcase,
  });

  /// Never null: without the extension the default look fills everything.
  static CityTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<CityTheme>() ?? CityTheme.fallback(theme.brightness);
  }

  /// The "Sello comunitario" look: no photo, no flag, today's colors.
  factory CityTheme.fallback(Brightness brightness) {
    final light = brightness == Brightness.light;
    final primary = light ? AppColors.ink : AppColors.mustard;
    return CityTheme(
      slug: 'default',
      displayName: '',
      department: '',
      level: CityIdentityLevel.fallback,
      dayPart: DayPart.morning,
      hero: null,
      heroDescription: null,
      flag: const [],
      accent: AppColors.mustard,
      onAccent: AppColors.inkDeep,
      deep: primary,
      onDeep: light ? Colors.white : AppColors.inkDeep,
      veil: AppColors.inkDeep,
      navSelected: primary,
      navPill: Colors.transparent,
      landmarks: const [
        CityLandmark(rankName: 'Observador Urbano', title: 'Observador Urbano'),
        CityLandmark(rankName: 'Vecino Activo', title: 'Vecino Activo'),
        CityLandmark(rankName: 'Guardián Vial', title: 'Guardián Vial'),
        CityLandmark(rankName: 'Veedor Mayor', title: 'Veedor Mayor'),
      ],
      copy: const CityThemeCopy(
        greeting: 'Buenos días',
        slogan: 'Tu ciudad se cuida entre vecinos.',
        validationCheer: '¡Reporte validado!',
        climbTitle: 'Tu subida cívica',
      ),
      showcase: const [],
    );
  }

  /// Turns the pack of the active city into what the widgets draw.
  ///
  /// [reference] is the citizen's own city (`reference_city`): their rank climb
  /// keeps its places even while they explore another one.
  factory CityTheme.from(
    CityIdentity identity,
    Brightness brightness,
    DayPart dayPart, {
    CityIdentity? reference,
    List<CityIdentity> featured = const [],
  }) {
    final light = brightness == Brightness.light;
    final isFallback = identity.level == CityIdentityLevel.fallback;
    final palette = identity.palette;
    final accent = Color(palette.accent);
    final onAccent = Color(palette.onAccent);
    final deep = light ? Color(palette.deep) : accent;
    final hero = identity.heroes[dayPart];
    final climb = reference ?? identity;

    return CityTheme(
      slug: identity.slug,
      displayName: identity.name,
      department: identity.department,
      level: identity.level,
      dayPart: dayPart,
      hero: hero == null ? null : _photo(hero.assetPath, AppSizes.heroCacheWidth),
      heroDescription: hero?.description,
      flag: _flag(palette),
      accent: accent,
      onAccent: onAccent,
      deep: deep,
      onDeep: light ? Colors.white : onAccent,
      veil: Color(palette.veil),
      navSelected: isFallback ? deep : (light ? AppColors.ink : AppColors.cream),
      navPill: isFallback ? Colors.transparent : accent.withValues(alpha: 0.38),
      landmarks: [
        for (final landmark in climb.landmarks)
          CityLandmark(
            rankName: landmark.rankName,
            title: landmark.title,
            medal: landmark.photo == null ? null : _photo(landmark.photo!.assetPath, AppSizes.medalCacheWidth),
            photo: landmark.photo == null ? null : _photo(landmark.photo!.assetPath, AppSizes.rankCacheWidth),
            photoDescription: landmark.photo?.description,
          ),
      ],
      copy: CityThemeCopy(
        greeting: identity.copy.greetingFor(dayPart),
        slogan: identity.copy.slogan,
        validationCheer: identity.copy.validationCheer,
        climbTitle: climb.copy.climbTitle,
      ),
      showcase: [
        for (final city in featured)
          CityShowcase(
            name: city.name,
            department: city.department,
            veil: Color(city.palette.veil),
            flag: _flag(city.palette),
            card: _showcasePhoto(city, dayPart, AppSizes.cardCacheWidth),
            thumbnail: _showcasePhoto(city, DayPart.afternoon, AppSizes.medalCacheWidth),
          ),
      ],
    );
  }

  static ImageProvider _photo(String path, int cacheWidth) =>
      ResizeImage(AssetImage(path), width: cacheWidth);

  static ImageProvider? _showcasePhoto(CityIdentity city, DayPart part, int cacheWidth) {
    final photo = city.heroes[part];
    return photo == null ? null : _photo(photo.assetPath, cacheWidth);
  }

  static List<CityFlagBand> _flag(CityPalette palette) =>
      [for (final band in palette.flag) CityFlagBand(Color(band.color), band.weight)];

  /// The featured city called [name], or null.
  CityShowcase? showcaseFor(String name, {String? department}) {
    final wanted = normalizeSearchText(name.trim());
    for (final city in showcase) {
      if (normalizeSearchText(city.name) != wanted) continue;
      if (department == null || normalizeSearchText(city.department) == normalizeSearchText(department.trim())) {
        return city;
      }
    }
    return null;
  }

  @override
  CityTheme copyWith({
    Color? accent,
    Color? onAccent,
    Color? deep,
    Color? onDeep,
    Color? veil,
    Color? navSelected,
    Color? navPill,
  }) {
    return CityTheme(
      slug: slug,
      displayName: displayName,
      department: department,
      level: level,
      dayPart: dayPart,
      hero: hero,
      heroDescription: heroDescription,
      flag: flag,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      deep: deep ?? this.deep,
      onDeep: onDeep ?? this.onDeep,
      veil: veil ?? this.veil,
      navSelected: navSelected ?? this.navSelected,
      navPill: navPill ?? this.navPill,
      landmarks: landmarks,
      copy: copy,
      showcase: showcase,
    );
  }

  /// Colors blend; photos, flag and words switch half way.
  @override
  CityTheme lerp(ThemeExtension<CityTheme>? other, double t) {
    if (other is! CityTheme) return this;
    return (t < 0.5 ? this : other).copyWith(
      accent: Color.lerp(accent, other.accent, t),
      onAccent: Color.lerp(onAccent, other.onAccent, t),
      deep: Color.lerp(deep, other.deep, t),
      onDeep: Color.lerp(onDeep, other.onDeep, t),
      veil: Color.lerp(veil, other.veil, t),
      navSelected: Color.lerp(navSelected, other.navSelected, t),
      navPill: Color.lerp(navPill, other.navPill, t),
    );
  }
}

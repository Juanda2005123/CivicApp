import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_colors.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/theme/city_theme.dart';
import 'package:vigia_app/core/theme/severity_colors.dart';
import 'package:vigia_app/core/widgets/city/city_hero.dart';
import 'package:vigia_app/features/city_identity/data/datasources/city_pack_local_data_source.dart';
import 'package:vigia_app/features/city_identity/domain/entities/day_part.dart';

import 'app_theme_test.dart' show contrast;

/// The color schemes of the app before the city identity ("Sello comunitario").
/// The default look must keep producing exactly these.
const _todayLight = ColorScheme(
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

const _todayDark = ColorScheme(
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

void main() {
  final packs = CityPackLocalDataSource();

  ThemeData themeOf(String city, Brightness brightness) => AppTheme.build(
        brightness,
        CityTheme.from(
          packs.findFullPack(city) ?? packs.getDefaultPack(),
          brightness,
          DayPart.afternoon,
          featured: packs.getFullPacks(),
        ),
      );

  group('regression: the default pack looks like the app of before', () {
    for (final (brightness, today, semantic, severity) in [
      (Brightness.light, _todayLight, AppSemanticColors.light, AppSeverityColors.light),
      (Brightness.dark, _todayDark, AppSemanticColors.dark, AppSeverityColors.dark),
    ]) {
      test('${brightness.name}: same color scheme and extensions', () {
        final theme = themeOf('none', brightness);

        expect(theme.colorScheme, today);
        expect(theme.extension<AppSemanticColors>(), same(semantic));
        expect(theme.extension<AppSeverityColors>(), same(severity));
        expect(theme.floatingActionButtonTheme.backgroundColor, today.primary);
        expect(theme.bottomNavigationBarTheme.selectedItemColor, today.primary);
        expect(theme.switchTheme, const SwitchThemeData());
        expect(theme.chipTheme, const ChipThemeData());
        expect(theme.inputDecorationTheme.floatingLabelStyle, isNull);
        expect(theme.extension<CityTheme>()!.hero, isNull);
        expect(theme.extension<CityTheme>()!.flag, isEmpty);
      });

      test('${brightness.name}: the built-in fallback matches the default pack', () {
        final fromPack = themeOf('none', brightness).extension<CityTheme>()!;
        final fallback = CityTheme.fallback(brightness);

        expect(fromPack.accent, fallback.accent);
        expect(fromPack.onAccent, fallback.onAccent);
        expect(fromPack.deep, fallback.deep);
        expect(fromPack.onDeep, fallback.onDeep);
        expect(fromPack.veil, fallback.veil);
        expect(fromPack.navPill, fallback.navPill);
        expect(fromPack.navSelected, fallback.navSelected);
        expect(fromPack.landmarks.map((l) => l.title), fallback.landmarks.map((l) => l.title));
        expect(fromPack.copy.climbTitle, fallback.copy.climbTitle);
      });
    }
  });

  // Every registered pack, so a new city with a weak palette fails here.
  group('contrast of every city pack (WCAG AA)', () {
    for (final pack in [...packs.getFullPacks(), packs.getDefaultPack()]) {
      final palette = pack.palette;

      test('${pack.slug}: white on deep, onAccent on accent and white on the veil reach 4.5:1', () {
        expect(contrast(Colors.white, Color(palette.deep)), greaterThanOrEqualTo(4.5), reason: 'deep');
        expect(contrast(Color(palette.onAccent), Color(palette.accent)), greaterThanOrEqualTo(4.5), reason: 'accent');
        expect(contrast(Colors.white, Color(palette.veil)), greaterThanOrEqualTo(4.5), reason: 'veil');
      });

      for (final brightness in Brightness.values) {
        test('${pack.slug} ${brightness.name}: links, labels and buttons can be read', () {
          final theme = AppTheme.build(brightness, CityTheme.from(pack, brightness, DayPart.morning));
          final scheme = theme.colorScheme;
          final city = theme.extension<CityTheme>()!;

          for (final surface in [scheme.surface, scheme.surfaceContainerLow]) {
            expect(contrast(scheme.secondary, surface), greaterThanOrEqualTo(4.5), reason: 'link');
            expect(contrast(city.deep, surface), greaterThanOrEqualTo(4.5), reason: 'highlight');
          }
          expect(contrast(scheme.onPrimary, scheme.primary), greaterThanOrEqualTo(4.5));
          expect(contrast(scheme.onSecondary, scheme.secondary), greaterThanOrEqualTo(4.5));
          expect(contrast(city.onDeep, city.deep), greaterThanOrEqualTo(4.5));
          // The accent is also used as text over the veil (celebrations).
          expect(contrast(city.accent, city.veil), greaterThanOrEqualTo(4.5));
        });
      }
    }
  });

  test('white text passes AA over the veil of the header, even on a white photo', () {
    for (final pack in packs.getFullPacks()) {
      final behind = Color.alphaBlend(
        Color(pack.palette.veil).withValues(alpha: CityHero.textVeil),
        Colors.white,
      );

      expect(contrast(Colors.white, behind), greaterThanOrEqualTo(4.5), reason: pack.slug);
    }
  });

  group('Material defaults that use the primary color read in a city', () {
    for (final city in ['Cali', 'Medellín']) {
      for (final brightness in Brightness.values) {
        test('$city ${brightness.name}: chip icons, focused labels and switches', () {
          final theme = themeOf(city, brightness);
          final scheme = theme.colorScheme;
          final label = theme.inputDecorationTheme.floatingLabelStyle! as WidgetStateTextStyle;

          expect(theme.chipTheme.iconTheme?.color, scheme.secondary);
          expect(label.resolve({WidgetState.focused}).color, scheme.secondary);
          expect(label.resolve({WidgetState.error}).color, scheme.error);
          expect(theme.switchTheme.trackColor?.resolve({WidgetState.selected}), scheme.secondary);
          expect(
            contrast(theme.switchTheme.thumbColor!.resolve({WidgetState.selected})!, scheme.secondary),
            greaterThanOrEqualTo(3),
          );
        });
      }
    }
  });

  group('Cali and Medellín', () {
    test('the accent paints the main buttons and "Reportar" in both themes', () {
      for (final (city, accent) in [('Cali', const Color(0xFFF08A24)), ('Medellín', const Color(0xFFF4B400))]) {
        for (final brightness in Brightness.values) {
          final theme = themeOf(city, brightness);

          expect(theme.colorScheme.primary, accent);
          expect(theme.colorScheme.primaryContainer, accent);
          expect(theme.floatingActionButtonTheme.backgroundColor, accent);
        }
      }
    });

    test('light uses the deep tone for chips and links; dark uses the accent', () {
      expect(themeOf('Cali', Brightness.light).colorScheme.secondary, const Color(0xFF1B4B5F));
      expect(themeOf('Cali', Brightness.light).colorScheme.secondaryContainer, const Color(0xFF1B4B5F));
      expect(themeOf('Cali', Brightness.dark).colorScheme.secondary, const Color(0xFFF08A24));
      expect(themeOf('Medellín', Brightness.light).colorScheme.secondary, const Color(0xFF0E6B3F));
    });

    test('surfaces, text, errors and severity are the same as everywhere', () {
      for (final brightness in Brightness.values) {
        final base = themeOf('none', brightness);
        final cali = themeOf('Cali', brightness);

        expect(cali.colorScheme.surface, base.colorScheme.surface);
        expect(cali.colorScheme.surfaceContainerLow, base.colorScheme.surfaceContainerLow);
        expect(cali.colorScheme.onSurface, base.colorScheme.onSurface);
        expect(cali.colorScheme.error, base.colorScheme.error);
        expect(cali.extension<AppSeverityColors>(), same(base.extension<AppSeverityColors>()));
      }
    });

    test('the citizen keeps the places of their own city while exploring another', () {
      final theme = CityTheme.from(
        packs.findFullPack('Medellín')!,
        Brightness.light,
        DayPart.morning,
        reference: packs.findFullPack('Cali'),
      );

      expect(theme.displayName, 'Medellín');
      expect(theme.copy.greeting, '¡Buenos días, parce!');
      expect(theme.landmarks.map((l) => l.title),
          ['Gato del Río', 'La Ermita', 'Cristo Rey', 'Cerro de las Tres Cruces']);
      expect(theme.copy.climbTitle, 'Tu subida al Cerro de las Tres Cruces');
    });

    test('the moment of the day picks the photo and the greeting', () {
      final cali = packs.findFullPack('Cali')!;
      final night = CityTheme.from(cali, Brightness.light, DayPart.night);

      expect(night.copy.greeting, '¡Buenas noches, ve!');
      expect(night.heroDescription, 'El oeste de Cali de noche');
      expect(CityTheme.from(cali, Brightness.light, DayPart.afternoon).heroDescription, 'Cerro de las Tres Cruces');
    });

    test('featured cities are found by name for their thumbnails', () {
      final theme = themeOf('Cali', Brightness.light).extension<CityTheme>()!;

      expect(theme.showcase.map((city) => city.name), ['Cali', 'Medellín']);
      expect(theme.showcaseFor('medellin')?.name, 'Medellín');
      expect(theme.showcaseFor('Pasto'), isNull);
    });
  });
}

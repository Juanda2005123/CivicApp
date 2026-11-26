import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/city_theme.dart';
import 'package:vigia_app/core/widgets/brand_seal.dart';
import 'package:vigia_app/core/widgets/city/celebration_overlay.dart';
import 'package:vigia_app/core/widgets/rank_seal.dart';

import '../../support/city_theme_host.dart';

void main() {
  const cheers = {'Cali': '¡Eso, ve!', 'Medellín': '¡Qué chimba, parce!', null: '¡Reporte validado!'};

  final confetti = find.byKey(const ValueKey('confetti'));
  Finder inside(Type celebration, Type widget) =>
      find.descendant(of: find.byType(celebration), matching: find.byType(widget));

  /// Widgets of [type] in the column of words and seal of [celebration] (the
  /// scroll view around it has its own overscroll transform).
  Finder inContent(Type celebration, Type type) => find.descendant(
        of: find.descendant(of: inside(celebration, SingleChildScrollView), matching: find.byType(Column)).first,
        matching: find.byType(type),
      );

  /// Opens the celebration from a button, as a screen would.
  Future<void> open(
    WidgetTester tester,
    Future<void> Function(BuildContext context) show, {
    String? city,
    Brightness brightness = Brightness.light,
    bool reduceMotion = false,
  }) async {
    await tester.pumpWidget(cityHost(
      Builder(builder: (context) => TextButton(onPressed: () => show(context), child: const Text('abrir'))),
      city: city,
      brightness: brightness,
      reduceMotion: reduceMotion,
    ));
    await tester.tap(find.text('abrir'));
    await tester.pump();
  }

  Future<void> validated(BuildContext context) =>
      showValidationCelebration(context, reportCode: '#VIG-1042', endorsements: 10);

  Future<void> newRank(BuildContext context) => showRankCelebration(
        context,
        level: 3,
        rankName: 'Guardián Vial',
        place: CityTheme.of(context).landmarks[2],
        points: 2500,
        origin: const Offset(40, 300),
      );

  group('validated report (3A)', () {
    for (final city in testCities) {
      for (final brightness in Brightness.values) {
        testWidgets('${city ?? 'default'} ${brightness.name}: seal, cheer, confetti and the bonus', (tester) async {
          await open(tester, validated, city: city, brightness: brightness);
          await tester.pump(const Duration(milliseconds: 800));

          expect(find.text(cheers[city]!), findsOneWidget);
          expect(find.text('REPORTE #VIG-1042'), findsOneWidget);
          expect(find.text('VALIDADO'), findsOneWidget);
          expect(find.text('10 vecinos confirmaron el daño. Ya tiene el sello de la comunidad.'), findsOneWidget);
          expect(find.text('+500 XP para quien lo reportó'), findsOneWidget);
          expect(confetti, findsOneWidget);
          expect(inContent(ValidationCelebration, Transform), findsWidgets);
          // A city shows its place inside the seal; the default look, the brand seal.
          expect(inside(ValidationCelebration, Image), city == null ? findsNothing : findsOneWidget);
          expect(inside(ValidationCelebration, BrandSeal), city == null ? findsOneWidget : findsNothing);

          await tester.pumpAndSettle();
        });
      }

      testWidgets('${city ?? 'default'}: with reduced motion it only fades: no confetti, scale or turn',
          (tester) async {
        await open(tester, validated, city: city, reduceMotion: true);
        await tester.pump(const Duration(milliseconds: 50));

        final fade = tester.widget<FadeTransition>(
          find.ancestor(of: find.byType(ValidationCelebration), matching: find.byType(FadeTransition)).first,
        );
        expect(fade.opacity.value, inExclusiveRange(0, 1));
        await tester.pump(const Duration(milliseconds: 60));
        expect(fade.opacity.value, 1);

        expect(find.text('VALIDADO'), findsOneWidget);
        expect(confetti, findsNothing);
        expect(inContent(ValidationCelebration, Transform), findsNothing);
        await tester.pumpAndSettle();
      });
    }

    testWidgets('closes by itself after 2.5 s', (tester) async {
      await open(tester, validated, city: 'Cali');
      await tester.pump(const Duration(milliseconds: 2400));
      expect(find.byType(ValidationCelebration), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byType(ValidationCelebration), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
    });

    testWidgets('closes with a tap, once', (tester) async {
      await open(tester, validated, city: 'Cali');
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byType(ValidationCelebration));
      await tester.pumpAndSettle();

      expect(find.byType(ValidationCelebration), findsNothing);
      expect(find.text('abrir'), findsOneWidget, reason: 'the screen underneath is not popped too');
    });

    testWidgets('reads as one announcement', (tester) async {
      await open(tester, validated, city: 'Cali');
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.bySemanticsLabel(RegExp(r'^Reporte #VIG-1042 validado\. ¡Eso, ve! .*Toca para cerrar\.$')),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });
  });

  group('new rank (4C)', () {
    const places = {'Cali': 'Cristo Rey', 'Medellín': 'Metrocable'};

    for (final city in places.keys) {
      for (final brightness in Brightness.values) {
        testWidgets('$city ${brightness.name}: the photo opens in a circle from the medal', (tester) async {
          await open(tester, newRank, city: city, brightness: brightness);
          await tester.pump(const Duration(milliseconds: 200));

          final clip = tester.widget<ClipPath>(
            find.ancestor(of: find.byType(RankCelebration), matching: find.byType(ClipPath)).first,
          );
          final clipper = clip.clipper! as CircleRevealClipper;
          expect(clipper.origin, const Offset(40, 300));
          expect(clipper.share, inExclusiveRange(0, 1));

          await tester.pump(const Duration(milliseconds: 500));
          expect(find.text(places[city]!), findsOneWidget);
          expect(find.text('NUEVO RANGO · GUARDIÁN VIAL'), findsOneWidget);
          expect(find.text('2500 pts'), findsOneWidget);
          expect(inside(RankCelebration, Image), findsOneWidget);
          await tester.pumpAndSettle();
        });
      }
    }

    testWidgets('default look: the rank seal and its name', (tester) async {
      await open(tester, newRank, brightness: Brightness.dark);
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('NUEVO RANGO · NIVEL 3'), findsOneWidget);
      expect(find.text('Guardián Vial'), findsOneWidget);
      expect(inside(RankCelebration, RankSeal), findsOneWidget);
      await tester.pumpAndSettle();
    });

    for (final city in testCities) {
      testWidgets('${city ?? 'default'}: with reduced motion it fades in, without the circle', (tester) async {
        await open(tester, newRank, city: city, reduceMotion: true);
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.ancestor(of: find.byType(RankCelebration), matching: find.byType(ClipPath)), findsNothing);
        expect(inContent(RankCelebration, Transform), findsNothing);
        await tester.pumpAndSettle();
      });
    }

    testWidgets('closes by itself after 2.6 s', (tester) async {
      await open(tester, newRank, city: 'Medellín');
      await tester.pump(const Duration(milliseconds: 2500));
      expect(find.byType(RankCelebration), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byType(RankCelebration), findsNothing);
    });
  });
}

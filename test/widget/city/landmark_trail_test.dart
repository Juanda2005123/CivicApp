import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/widgets/city/landmark_trail.dart';
import 'package:vigia_app/core/widgets/rank_seal.dart';

import '../../support/city_theme_host.dart';

const _ranks = [
  TrailRank(level: 1, name: 'Observador Urbano', minXp: 0),
  TrailRank(level: 2, name: 'Vecino Activo', minXp: 1000),
  TrailRank(level: 3, name: 'Guardián Vial', minXp: 2500),
  TrailRank(level: 4, name: 'Veedor Mayor', minXp: 4000),
];

Widget _trail({int level = 2, List<TrailRank> ranks = _ranks}) => SingleChildScrollView(
      child: LandmarkTrail(
        ranks: ranks,
        currentLevel: level,
        title: 'Tu avance',
        progress: 0.28,
        points: '1420 / 2500 pts',
        caption: 'Te faltan 1080 pts para el Nivel 3 · Guardián Vial.',
      ),
    );

void main() {
  const places = {
    'Cali': ['Gato del Río', 'La Ermita', 'Cristo Rey', 'Cerro de las Tres Cruces'],
    'Medellín': ['Comuna 13', 'Plaza Botero', 'Metrocable', 'Pueblito Paisa'],
  };

  for (final city in places.keys) {
    for (final brightness in Brightness.values) {
      testWidgets('$city ${brightness.name}: the four places, summit first, with "TÚ" on the current one',
          (tester) async {
        tester.view.physicalSize = const Size(400, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(cityHost(_trail(), city: city, brightness: brightness));
        await tester.pumpAndSettle();

        final names = places[city]!;
        expect(find.text('Vas por ${names[1]}'), findsOneWidget);
        expect(find.text('Tu avance'), findsOneWidget);
        expect(find.text('1420 / 2500 pts'), findsOneWidget);
        expect(find.text('Nivel actual: 2'), findsOneWidget);
        for (final name in names) {
          expect(find.text(name), findsOneWidget);
        }
        expect(tester.getTopLeft(find.text(names[3])).dy, lessThan(tester.getTopLeft(find.text(names[0])).dy));
        expect(find.text('TÚ'), findsOneWidget);
        expect(find.text('LOGRADO'), findsOneWidget);
        expect(find.text('SIGUIENTE'), findsOneWidget);
        expect(find.text('2500 XP · Guardián Vial'), findsOneWidget);
        expect(find.byType(Image), findsNWidgets(4));
        expect(find.bySemanticsLabel('${names[1]}, 1000 XP · Vecino Activo, logrado, aquí vas'), findsOneWidget);
        expect(find.bySemanticsLabel('${names[2]}, 2500 XP · Guardián Vial, pendiente'), findsOneWidget);
        expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, 0.28);
      });
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('default look ${brightness.name}: rank seals and rank names, no photos', (tester) async {
      await tester.pumpWidget(cityHost(_trail(), brightness: brightness));
      await tester.pumpAndSettle();

      expect(find.text('Tu avance'), findsOneWidget);
      expect(find.text('Nivel actual: 2'), findsOneWidget);
      expect(find.text('Vecino Activo'), findsOneWidget);
      expect(find.text('1000 XP'), findsOneWidget);
      expect(find.textContaining('Vas por'), findsNothing);
      expect(find.byType(Image), findsNothing);
      // The heading seal and the four steps.
      expect(find.byType(RankSeal), findsNWidgets(5));
    });
  }

  testWidgets('at the highest rank it says where the citizen arrived', (tester) async {
    await tester.pumpWidget(cityHost(_trail(level: 4), city: 'Cali'));
    await tester.pumpAndSettle();

    expect(find.text('Llegaste a Cerro de las Tres Cruces'), findsOneWidget);
    expect(find.text('SIGUIENTE'), findsNothing);
  });

  testWidgets('a rank with another name takes the place of its position', (tester) async {
    const renamed = [
      TrailRank(level: 1, name: 'Observador Urbano', minXp: 0),
      TrailRank(level: 2, name: 'Vecino Vigilante', minXp: 1000),
      TrailRank(level: 3, name: 'Guardián Cívico', minXp: 2500),
    ];

    await tester.pumpWidget(cityHost(_trail(ranks: renamed), city: 'Medellín'));
    await tester.pumpAndSettle();

    expect(find.text('Vas por Plaza Botero'), findsOneWidget);
    expect(find.text('1000 XP · Vecino Vigilante'), findsOneWidget);
  });

  for (final city in testCities) {
    testWidgets('${city ?? 'default'}: still with reduced motion and whole at 200 % text', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(cityHost(_trail(), city: city, reduceMotion: true, textScale: 2));
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}

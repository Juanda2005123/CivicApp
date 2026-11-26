import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/widgets/city/city_hero.dart';
import 'package:vigia_app/core/widgets/city/flag_stripe.dart';

import '../../support/city_theme_host.dart';

void main() {
  const greetings = {'Cali': '¡Qué más, ve!', 'Medellín': '¡Quiubo, parce!'};
  const places = {'Cali': 'Cali, Valle del Cauca · tarde', 'Medellín': 'Medellín, Antioquia · tarde'};
  const photos = {'Cali': 'Cerro de las Tres Cruces', 'Medellín': 'Metrocable sobre la Comuna 1'};

  /// The scale the zoom applies to the photo right now.
  double zoomOf(WidgetTester tester) {
    final transform = tester.widget<Transform>(
      find.ancestor(of: find.byType(Image), matching: find.byType(Transform)).first,
    );
    return transform.transform.getMaxScaleOnAxis();
  }

  for (final city in testCities.whereType<String>()) {
    for (final brightness in Brightness.values) {
      testWidgets('$city ${brightness.name}: photo, flag, greeting and slogan of the afternoon', (tester) async {
        await tester.pumpWidget(cityHost(const CityHero(), city: city, brightness: brightness));
        await tester.pump();

        expect(find.text(greetings[city]!), findsOneWidget);
        expect(find.text('$city se cuida entre vecinos.'), findsOneWidget);
        expect(find.text(places[city]!.toUpperCase()), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(places[city]!)), findsOneWidget);
        expect(find.byType(FlagStripe), findsOneWidget);
        expect(tester.widget<Image>(find.byType(Image)).semanticLabel, photos[city]);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('default look ${brightness.name}: draws nothing', (tester) async {
      await tester.pumpWidget(cityHost(const Column(children: [CityHero()]), brightness: brightness));

      expect(tester.getSize(find.byType(CityHero)), Size.zero);
      expect(find.byType(Image), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  }

  testWidgets('the photo zooms slowly, from 1 to 1.1 and back (6A)', (tester) async {
    await tester.pumpWidget(cityHost(const CityHero(), city: 'Cali'));
    await tester.pump();
    expect(zoomOf(tester), 1);

    await tester.pump(const Duration(seconds: 10));
    expect(zoomOf(tester), greaterThan(1.02));

    await tester.pump(const Duration(seconds: 10));
    expect(zoomOf(tester), closeTo(1.1, 0.001));

    await tester.pump(const Duration(seconds: 10));
    expect(zoomOf(tester), lessThan(1.1));
  });

  testWidgets('with reduced motion the photo stays still', (tester) async {
    await tester.pumpWidget(cityHost(const CityHero(), city: 'Cali', reduceMotion: true));
    await tester.pump(const Duration(seconds: 10));

    expect(zoomOf(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the zoom rests while the header is scrolled out of view', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(cityHost(
      ListView(controller: scroll, children: const [CityHero(), SizedBox(height: 2000)]),
      city: 'Medellín',
    ));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);

    scroll.jumpTo(400);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);

    scroll.jumpTo(0);
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('a hidden tab does not animate', (tester) async {
    await tester.pumpWidget(cityHost(const TickerMode(enabled: false, child: CityHero()), city: 'Cali'));
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the short header of the login names the city and is still', (tester) async {
    await tester.pumpWidget(cityHost(const CityHero(compact: true), city: 'Cali'));
    await tester.pumpAndSettle();

    expect(find.text('CALI, VALLE DEL CAUCA'), findsOneWidget);
    expect(find.text('Cali se cuida entre vecinos.'), findsOneWidget);
    expect(find.text('¡Qué más, ve!'), findsNothing);
  });

  testWidgets('text at 200 % makes the header grow instead of cutting it', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(cityHost(
      const SingleChildScrollView(child: CityHero()),
      city: 'Medellín',
      textScale: 2,
    ));
    await tester.pump();

    expect(tester.getSize(find.byType(CityHero)).height, greaterThanOrEqualTo(240));
    expect(tester.takeException(), isNull);
  });
}

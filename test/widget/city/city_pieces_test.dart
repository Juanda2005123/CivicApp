import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/city_theme.dart';
import 'package:vigia_app/core/widgets/city/city_photo_card.dart';
import 'package:vigia_app/core/widgets/city/city_skeleton.dart';
import 'package:vigia_app/core/widgets/city/flag_stripe.dart';
import 'package:vigia_app/core/widgets/dotted_spinner.dart';

import '../../support/city_theme_host.dart';

void main() {
  group('FlagStripe', () {
    for (final (city, weights) in [('Cali', [3, 1, 3, 1, 3]), ('Medellín', [1, 1])]) {
      testWidgets('$city: one segment per band, with its weight', (tester) async {
        await tester.pumpWidget(cityHost(const Center(child: FlagStripe()), city: city));

        final bands = tester.widgetList<Expanded>(
          find.descendant(of: find.byType(FlagStripe), matching: find.byType(Expanded)),
        );
        expect(bands.map((band) => band.flex), weights);
      });
    }

    testWidgets('the default look has no flag', (tester) async {
      await tester.pumpWidget(cityHost(const Center(child: FlagStripe())));

      expect(tester.getSize(find.byType(FlagStripe)), Size.zero);
    });
  });

  group('CitySkeleton (8D)', () {
    for (final shape in CitySkeletonShape.values) {
      testWidgets('${shape.name}: fits a small screen and is announced at once, drawn after 300 ms', (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(cityHost(
          SingleChildScrollView(
            child: CitySkeleton(shape: shape, semanticLabel: 'Cargando', fill: false),
          ),
          city: 'Cali',
        ));
        final opacity = find.descendant(of: find.byType(CitySkeleton), matching: find.byType(Opacity)).first;

        expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
        expect(tester.widget<Opacity>(opacity).opacity, 0);
        await tester.pump(const Duration(milliseconds: 320));
        expect(tester.widget<Opacity>(opacity).opacity, 1);
        expect(find.byType(ShaderMask), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    for (final brightness in Brightness.values) {
      testWidgets('${brightness.name}: with reduced motion the shapes stay still, without shine', (tester) async {
        await tester.pumpWidget(cityHost(
          const CitySkeleton(shape: CitySkeletonShape.feed, semanticLabel: 'Cargando'),
          brightness: brightness,
          reduceMotion: true,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(ShaderMask), findsNothing);
      });
    }
  });

  group('CityPhotoCard', () {
    for (final city in ['Cali', 'Medellín']) {
      testWidgets('$city: name, department and flag; a tap selects it', (tester) async {
        var taps = 0;
        await tester.pumpWidget(cityHost(
          Builder(
            builder: (context) => CityPhotoCard(
              city: CityTheme.of(context).showcaseFor(city)!,
              selected: false,
              onTap: () => taps++,
            ),
          ),
          city: city,
        ));
        await tester.pump();

        expect(find.text(city), findsOneWidget);
        expect(find.byType(FlagStripe), findsOneWidget);
        await tester.tap(find.text(city));
        await tester.pumpAndSettle();
        expect(taps, 1);
      });
    }

    testWidgets('the selected one shows a check and says so; the GPS tag is spoken', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(cityHost(
        Builder(
          builder: (context) => CityPhotoCard(
            city: CityTheme.of(context).showcaseFor('Cali')!,
            selected: true,
            tag: 'Detectada por GPS',
            onTap: () {},
          ),
        ),
        city: 'Cali',
        textScale: 2,
      ));
      await tester.pump();

      expect(find.text('Detectada por GPS'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Cali, Valle del Cauca, Detectada por GPS')),
        isSemantics(isButton: true, isSelected: true),
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  });

  group('DottedSpinner in a city', () {
    testWidgets('appears only after 300 ms', (tester) async {
      await tester.pumpWidget(cityHost(const Center(child: DottedSpinner()), city: 'Cali'));
      final opacity = find.descendant(of: find.byType(DottedSpinner), matching: find.byType(Opacity));

      expect(tester.widget<Opacity>(opacity).opacity, 0);
      await tester.pump(const Duration(milliseconds: 320));
      expect(tester.widget<Opacity>(opacity).opacity, 1);
    });
  });
}

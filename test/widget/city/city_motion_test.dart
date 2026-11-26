import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/city_theme.dart';
import 'package:vigia_app/core/widgets/city/city_motion.dart';

import '../../support/city_theme_host.dart';

void main() {
  group('PressScale (1A)', () {
    Finder scaleOf() => find.descendant(of: find.byType(PressScale), matching: find.byType(ScaleTransition));

    testWidgets('the element sinks to 96 % while pressed and comes back; the tap still works', (tester) async {
      var taps = 0;
      await tester.pumpWidget(cityHost(Center(
        child: PressScale(child: FilledButton(onPressed: () => taps++, child: const Text('Apoyar'))),
      )));
      double scale() => tester.widget<ScaleTransition>(scaleOf().first).scale.value;

      final gesture = await tester.startGesture(tester.getCenter(find.text('Apoyar')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(scale(), closeTo(PressScale.pressedScale, 0.001));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(scale(), 1);
      expect(taps, 1);
    });

    testWidgets('a disabled button does not answer', (tester) async {
      await tester.pumpWidget(cityHost(const Center(
        child: PressScale(child: FilledButton(onPressed: null, child: Text('Apoyar'))),
      )));

      await tester.startGesture(tester.getCenter(find.text('Apoyar')));
      await tester.pump(const Duration(milliseconds: 60));

      expect(tester.widget<ScaleTransition>(scaleOf().first).scale.value, 1);
    });

    testWidgets('with reduced motion it fades instead of shrinking', (tester) async {
      await tester.pumpWidget(cityHost(
        Center(child: PressScale(child: FilledButton(onPressed: () {}, child: const Text('Apoyar')))),
        reduceMotion: true,
      ));

      final fade = find.ancestor(of: find.byType(FilledButton), matching: find.byType(FadeTransition)).first;
      final gesture = await tester.startGesture(tester.getCenter(find.text('Apoyar')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.descendant(of: find.byType(PressScale), matching: find.byType(ScaleTransition)), findsNothing);
      expect(tester.widget<FadeTransition>(fade).opacity.value, lessThan(1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.widget<FadeTransition>(fade).opacity.value, 1);
    });
  });

  group('shared axis between screens (5A)', () {
    Future<void> push(WidgetTester tester, {bool reduceMotion = false}) async {
      await tester.pumpWidget(cityHost(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Center(child: Text('Detalle')))),
            ),
            child: const Text('ver'),
          ),
        ),
        city: 'Cali',
        reduceMotion: reduceMotion,
      ));
      await tester.tap(find.text('ver'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
    }

    testWidgets('the new screen comes from the right and the old one leaves to the left', (tester) async {
      await push(tester);
      final coming = tester.getCenter(find.text('Detalle')).dx;
      final leaving = tester.getTopLeft(find.text('ver', skipOffstage: false)).dx;
      await tester.pumpAndSettle();
      final end = tester.getCenter(find.text('Detalle')).dx;

      expect(coming - end, inExclusiveRange(0, SharedAxisPageTransitionsBuilder.enterOffset + 0.01));
      expect(leaving, lessThan(0), reason: 'the old screen slid to the left of its place');
    });

    testWidgets('with reduced motion it only fades, without moving', (tester) async {
      await push(tester, reduceMotion: true);
      final start = tester.getCenter(find.text('Detalle')).dx;
      await tester.pumpAndSettle();

      expect(tester.getCenter(find.text('Detalle')).dx, start);
    });
  });

  group('EndorseThumb (2D)', () {
    Widget thumb(int count, bool endorsed) => Center(
          child: EndorseThumb(
            icon: Icons.thumb_up,
            count: count,
            target: 10,
            endorsed: endorsed,
            color: Colors.black,
            burstColor: Colors.black,
          ),
        );

    testWidgets('endorsing makes a "+1" float up and then disappear', (tester) async {
      await tester.pumpWidget(cityHost(thumb(7, false), city: 'Cali'));
      expect(find.text('+1'), findsNothing);

      await tester.pumpWidget(cityHost(thumb(8, true), city: 'Cali'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final low = tester.getCenter(find.text('+1')).dy;
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getCenter(find.text('+1')).dy, lessThan(low));

      await tester.pumpAndSettle();
      expect(find.text('+1'), findsNothing);
    });

    testWidgets('taking the endorsement back, or a first drawing, does not celebrate', (tester) async {
      await tester.pumpWidget(cityHost(thumb(8, true)));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('+1'), findsNothing);

      await tester.pumpWidget(cityHost(thumb(7, false)));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('+1'), findsNothing);
    });

    testWidgets('with reduced motion nothing jumps or floats', (tester) async {
      await tester.pumpWidget(cityHost(thumb(7, false), reduceMotion: true));
      await tester.pumpWidget(cityHost(thumb(8, true), reduceMotion: true));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('+1'), findsNothing);
      await tester.pumpAndSettle();
    });
  });

  testWidgets('DelayedReveal shows nothing for the first 300 ms (8D)', (tester) async {
    await tester.pumpWidget(cityHost(const DelayedReveal(child: Text('cargando'))));
    double opacity() => tester.widget<Opacity>(find.ancestor(of: find.text('cargando'), matching: find.byType(Opacity)).first).opacity;

    await tester.pump(const Duration(milliseconds: 280));
    expect(opacity(), 0);

    await tester.pump(const Duration(milliseconds: 40));
    expect(opacity(), 1);
  });

  testWidgets('FlagCurtain covers the screen between its two sweeps (7A)', (tester) async {
    const flag = [CityFlagBand(Colors.white, 1), CityFlagBand(Colors.green, 1)];
    final progress = AnimationController(vsync: tester, duration: FlagCurtain.duration);
    addTearDown(progress.dispose);
    await tester.pumpWidget(cityHost(FlagCurtain(flag: flag, progress: progress)));
    final curtain = find.descendant(of: find.byType(FlagCurtain), matching: find.byType(CustomPaint));

    expect(curtain, paintsNothing);
    progress.value = FlagCurtain.coverShare;
    await tester.pump();
    expect(curtain, paints..rect(color: Colors.white)..rect(color: Colors.green));
    progress.value = 1;
    await tester.pump();
    expect(curtain, paintsNothing);
  });
}

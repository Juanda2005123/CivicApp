// "Mi perfil" needs a session, so its screenshots do not come from the web
// build: this renders the whole app with fake repositories (no network, no
// password) and saves the images.
//
//   flutter test tool/screenshots/profile_screenshots_test.dart
//
// It writes docs/design/screenshots/ciudad-viva/<city>-perfil-<theme>.png. It is
// not part of the test suite.
// A test file outside test/, so the test-only helpers are fine here.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigia_app/core/di/injection_container.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/dashboard/domain/entities/civic_impact.dart';
import 'package:vigia_app/features/dashboard/domain/entities/rank_level.dart';
import 'package:vigia_app/features/dashboard/ui/widgets/rank_climb.dart';
import 'package:vigia_app/main.dart';

import '../../test/support/fake_impact_repository.dart';
import '../../test/support/fakes.dart';

const _out = 'docs/design/screenshots/ciudad-viva';

const _cities = {
  'cali': City(
    id: 1,
    name: 'Cali',
    department: 'Valle del Cauca',
    latitude: 3.4516,
    longitude: -76.5320,
    isCapital: true,
  ),
  'medellin': City(
    id: 3,
    name: 'Medellín',
    department: 'Antioquia',
    latitude: 6.2442,
    longitude: -75.5812,
    isCapital: true,
  ),
  'bogota': City(
    id: 2,
    name: 'Bogotá',
    department: 'Bogotá D.C.',
    latitude: 4.7110,
    longitude: -74.0721,
    isCapital: true,
  ),
};

Future<void> _loadFonts() async {
  final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final family in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);
  tearDown(() => sl.reset());

  for (final MapEntry(key: slug, value: city) in _cities.entries) {
    for (final (theme, brightness) in [('claro', Brightness.light), ('oscuro', Brightness.dark)]) {
      testWidgets('$slug, perfil, $theme', (tester) async {
        debugDisableShadows = false;
        tester.view
          ..physicalSize = const Size(780, 1688)
          ..devicePixelRatio = 2;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        SharedPreferences.setMockInitialValues({});
        // The map's tile cache asks for a folder.
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );

        await initDependencies(
          authRepository: FakeAuthRepository(user: const AuthUser(id: 'uid-1', email: 'ana@example.com')),
          profileRepository: FakeProfileRepository()
            ..stored['uid-1'] = Profile(
              id: 'uid-1',
              email: 'ana@example.com',
              fullName: 'Ana Gómez',
              cityName: city.name,
              rankId: 2,
              rankName: 'Vecino Activo',
              experiencePoints: 1420,
            ),
          cityRepository: FakeCityRepository([city]),
          locationRepository: FakeLocationRepository(
            coordinates: Coordinates(latitude: city.latitude, longitude: city.longitude),
          ),
          incidentRepository: FakeIncidentRepository(),
          impactRepository: FakeImpactRepository()
            ..ranks = const [
              RankLevel(id: 1, name: 'Observador Urbano', minXp: 0),
              RankLevel(id: 2, name: 'Vecino Activo', minXp: 1000),
              RankLevel(id: 3, name: 'Guardián Vial', minXp: 2500),
              RankLevel(id: 4, name: 'Veedor Mayor', minXp: 4000),
            ]
            ..impact = const CivicImpact(
              reportsCreated: 6,
              endorsementsReceived: 23,
              endorsementsGiven: 14,
              commentsPublished: 9,
            ),
        );

        final boundary = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(key: boundary, child: const VigiaApp()));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(LucideIcons.circleUserRound));
        await tester.pumpAndSettle();
        // The climb, which is what changes from city to city.
        await Scrollable.ensureVisible(tester.element(find.byType(RankClimb)));
        await tester.pumpAndSettle();

        // Asset photos decode outside the test's fake clock.
        await tester.runAsync(() async {
          for (final element in find.byType(Image).evaluate().toList()) {
            await precacheImage((element.widget as Image).image, element);
          }
        });
        await tester.pumpAndSettle();

        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$_out/$slug-perfil-$theme.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        debugDisableShadows = true;
      });
    }
  }
}

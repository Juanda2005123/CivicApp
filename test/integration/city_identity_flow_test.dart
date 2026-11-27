import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigia_app/core/di/injection_container.dart';
import 'package:vigia_app/core/theme/city_theme.dart';
import 'package:vigia_app/core/widgets/city/city_photo_card.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/main.dart';

import '../support/fake_impact_repository.dart';
import '../support/fakes.dart';

const _cali = City(
  id: 1,
  name: 'Cali',
  department: 'Valle del Cauca',
  latitude: 3.4516,
  longitude: -76.5320,
  isCapital: true,
);
const _medellin = City(
  id: 3,
  name: 'Medellín',
  department: 'Antioquia',
  latitude: 6.2442,
  longitude: -75.5812,
  isCapital: true,
);

/// The real app with fake repositories: the city look reaches the theme from the
/// shell, the registration and the remembered city.
void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;

  Future<void> bootApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await initDependencies(
      authRepository: auth,
      profileRepository: profiles,
      cityRepository: FakeCityRepository(const [_cali, _medellin]),
      locationRepository: FakeLocationRepository(
        coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
      ),
      incidentRepository: FakeIncidentRepository(),
      impactRepository: FakeImpactRepository(),
    );
    await tester.pumpWidget(const VigiaApp());
    await tester.pumpAndSettle();
  }

  CityTheme themeOf(WidgetTester tester) =>
      CityTheme.of(tester.element(find.byType(Scaffold).first));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository();
  });

  tearDown(() => sl.reset());

  testWidgets('the shell dresses the app for the city of the map and the climb for the citizen\'s own',
      (tester) async {
    auth.user = const AuthUser(id: 'uid-1', email: 'ana@example.com');
    profiles.stored['uid-1'] = caliProfile;

    await bootApp(tester);

    expect(themeOf(tester).slug, 'cali');
    final scheme = Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme;
    expect(scheme.primary, const Color(0xFFF08A24));

    await tester.tap(find.byIcon(LucideIcons.circleUserRound));
    await tester.pumpAndSettle();
    expect(find.text('Vas por Gato del Río'), findsOneWidget);
    expect(find.text('TÚ'), findsOneWidget);
  });

  testWidgets('the next launch opens dressed for the last city, with its flag on the splash', (tester) async {
    SharedPreferences.setMockInitialValues({
      'city_identity.last_city_name': 'Medellín',
      'city_identity.last_city_department': 'Antioquia',
    });

    await bootApp(tester);

    // No session: the login, already wearing Medellín.
    expect(find.text('Ingresar'), findsOneWidget);
    expect(themeOf(tester).slug, 'medellin');
    expect(find.text('MEDELLÍN, ANTIOQUIA'), findsOneWidget);
    expect(find.text('Medellín se cuida entre vecinos.'), findsOneWidget);
  });

  testWidgets('picking a city card in the registration dresses the app for it', (tester) async {
    await bootApp(tester);
    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();
    expect(find.byType(CityPhotoCard), findsNWidgets(2));
    expect(themeOf(tester).slug, 'default');

    final card = find.byKey(const ValueKey('city-card-3'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(themeOf(tester).slug, 'medellin');
    expect(tester.widget<CityPhotoCard>(card).selected, isTrue);
    expect(find.text('Medellín (Antioquia)'), findsWidgets, reason: 'the list shows the same choice');
  });

  testWidgets('the GPS city goes first with its tag', (tester) async {
    await bootApp(tester);
    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();

    final detect = find.text('Detectar mi ciudad por GPS');
    await tester.ensureVisible(detect);
    await tester.tap(detect);
    await tester.pumpAndSettle();

    final first = tester.widget<CityPhotoCard>(find.byType(CityPhotoCard).first);
    expect(first.city.name, 'Cali');
    expect(first.tag, 'Detectada por GPS');
    expect(first.selected, isTrue);
    expect(themeOf(tester).slug, 'cali');
  });

  testWidgets('switching light and dark keeps the city', (tester) async {
    auth.user = const AuthUser(id: 'uid-1', email: 'ana@example.com');
    profiles.stored['uid-1'] = caliProfile;
    await bootApp(tester);

    await tester.tap(find.byTooltip('Cambiar a modo oscuro'));
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(Scaffold).first));
    expect(theme.brightness, Brightness.dark);
    expect(themeOf(tester).slug, 'cali');
    expect(theme.colorScheme.secondary, const Color(0xFFF08A24));
  });
}

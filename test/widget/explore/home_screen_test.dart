import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/theme/theme_cubit.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/open_location_settings_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_event.dart';
import 'package:vigia_app/features/explore/domain/usecases/get_city_options_usecase.dart';
import 'package:vigia_app/features/explore/domain/usecases/search_cities_usecase.dart';
import 'package:vigia_app/features/explore/ui/bloc/city_switcher_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/map_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/map_event.dart';
import 'package:vigia_app/features/explore/ui/screens/home_screen.dart';
import 'package:vigia_app/features/explore/ui/widgets/incident_map_marker.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_marker.dart';
import 'package:vigia_app/features/explore/domain/usecases/switch_city_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_city_map_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_current_location_usecase.dart';

import '../../support/fakes.dart';

const _cali = City(
  id: 1,
  name: 'Cali',
  department: 'Valle del Cauca',
  latitude: 3.4516,
  longitude: -76.5320,
  isCapital: true,
);
const _marker = IncidentMarker(
  id: 'inc-1',
  trackingCode: '#VIG-1001',
  title: 'Hueco en la Calle 5',
  categoryName: 'Hueco o bache en calzada',
  categoryIcon: 'warning',
  severity: IncidentSeverity.high,
  coordinates: Coordinates(latitude: 3.45, longitude: -76.53),
);

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeIncidentRepository incidents;
  late List<City> cities;
  late FakeLocationRepository location;
  late FakeRecentCitiesRepository recents;

  setUp(() {
    auth = FakeAuthRepository(user: const AuthUser(id: 'uid-1', email: 'ana@example.com'));
    profiles = FakeProfileRepository()
      ..stored['uid-1'] = const Profile(id: 'uid-1', email: 'ana@example.com', fullName: 'Ana Gomez', cityName: 'Cali');
    incidents = FakeIncidentRepository()..cityMarkers = [_marker];
    cities = const [_cali];
    recents = FakeRecentCitiesRepository();
    location = FakeLocationRepository(coordinates: const Coordinates(latitude: 3.40, longitude: -76.55));
  });

  // Blocs are created inside each test so their event loop runs in the
  // tester's fake async zone.
  Widget createShell() {
    final profileBloc = ProfileBloc(GetCurrentProfileUseCase(auth, profiles), SignOutUseCase(auth))
      ..add(ProfileStarted());
    final mapBloc = MapBloc(
      GetCityMapUseCase(auth, profiles, FakeCityRepository(cities), incidents, location),
      GetCurrentLocationUseCase(location),
      OpenLocationSettingsUseCase(location),
      SwitchCityUseCase(auth, profiles, recents),
    )..add(MapStarted());
    final switcherBloc = CitySwitcherBloc(
      GetCityOptionsUseCase(FakeCityRepository(cities), recents),
      SearchCitiesUseCase(),
    );
    addTearDown(profileBloc.close);
    addTearDown(mapBloc.close);
    addTearDown(switcherBloc.close);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider<ProfileBloc>.value(value: profileBloc),
        BlocProvider<MapBloc>.value(value: mapBloc),
        BlocProvider<CitySwitcherBloc>.value(value: switcherBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const HomeScreen(),
        routes: {
          AppRoutes.login: (context) => const Scaffold(body: Text('Login Screen Mock')),
          AppRoutes.register: (context) => const Scaffold(body: Text('Register Screen Mock')),
          // Stand-in for the wizard: it pops with a report or with nothing.
          AppRoutes.reportWizard: (context) => Scaffold(
                body: Column(
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context, 'published'), child: const Text('Publicar')),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                  ],
                ),
              ),
        },
      ),
    );
  }

  testWidgets('opens on Mapa with the bottom bar and the report button', (tester) async {
    await tester.pumpWidget(createShell());
    await tester.pumpAndSettle();

    expect(find.text('Mapa'), findsNWidgets(2)); // app bar title + tab label
    expect(find.byTooltip('Centrar en mi ubicación'), findsOneWidget);
    expect(find.text('Reportar daño'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('Mi perfil'), findsNWidgets(2));
    expect(find.text('Ana Gomez'), findsOneWidget);
  });

  testWidgets('the Mapa tab shows a marker per report of the city', (tester) async {
    // Permission denied on open: the map keeps the city view, where the report is.
    location = FakeLocationRepository(error: Exception('Sin permiso de ubicación. Elige tu ciudad en la lista.'));
    await tester.pumpWidget(createShell());
    await tester.pumpAndSettle();


    expect(find.byType(IncidentMapMarker), findsOneWidget);
    expect(find.bySemanticsLabel('Hueco en la Calle 5, Hueco o bache en calzada, gravedad Alta'), findsOneWidget);
  });

  testWidgets('with the permission granted the map opens centered on the citizen', (tester) async {
    await tester.pumpWidget(createShell());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Tu ubicación'), findsOneWidget);
  });

  testWidgets('denied on open, "Centrar en mi ubicación" asks again and shows the citizen', (tester) async {
    location = FakeLocationRepository(
      coordinates: const Coordinates(latitude: 3.40, longitude: -76.55),
      firstCallError: Exception('Sin permiso de ubicación. Elige tu ciudad en la lista.'),
    );
    await tester.pumpWidget(createShell());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Tu ubicación'), findsNothing);

    await tester.tap(find.byTooltip('Centrar en mi ubicación'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Tu ubicación'), findsOneWidget);
  });

  testWidgets('a blocked permission opens a modal that leads to the settings', (tester) async {
    location = FakeLocationRepository(error: Exception(LocationRepository.blockedMessage));
    await tester.pumpWidget(createShell());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Centrar en mi ubicación'));
    await tester.pumpAndSettle();

    expect(find.text('Ubicación bloqueada'), findsOneWidget);
    expect(find.text(LocationRepository.blockedMessage), findsOneWidget);

    await tester.tap(find.text('Abrir ajustes'));
    await tester.pumpAndSettle();

    expect(location.openSettingsCalls, 1);
    expect(find.text('Ubicación bloqueada'), findsNothing);
  });

  testWidgets('publishing a report reloads the map; cancelling does not', (tester) async {
    await tester.pumpWidget(createShell());
    await tester.pumpAndSettle();
    expect(incidents.calls.where((c) => c == 'incident.getCityIncidents'), hasLength(1));

    await tester.tap(find.text('Reportar daño'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(incidents.calls.where((c) => c == 'incident.getCityIncidents'), hasLength(1));

    await tester.tap(find.text('Reportar daño'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publicar'));
    await tester.pumpAndSettle();
    expect(incidents.calls.where((c) => c == 'incident.getCityIncidents'), hasLength(2));
  });

  group('guest (HU-22)', () {
    setUp(() => auth = FakeAuthRepository());

    testWidgets('sees the map and its reports without an account', (tester) async {
      // No GPS: the guest lands on the fallback city view, where the report is.
      location = FakeLocationRepository(error: Exception('Sin permiso de ubicación.'));
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      expect(find.byType(IncidentMapMarker), findsOneWidget);
      expect(find.text('Reportar daño'), findsOneWidget);
      expect(find.text('Login Screen Mock'), findsNothing);
    });

    testWidgets('"Reportar daño" opens the sign-in modal instead of the wizard', (tester) async {
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reportar daño'));
      await tester.pumpAndSettle();

      expect(find.text('Necesitas iniciar sesión'), findsOneWidget);
      expect(find.text('Publicar'), findsNothing);

      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Login Screen Mock'), findsOneWidget);
    });

    testWidgets('"Ahora no" closes the modal and stays on the map', (tester) async {
      // No GPS: the guest lands on the fallback city view, where the report is.
      location = FakeLocationRepository(error: Exception('Sin permiso de ubicación.'));
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reportar daño'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();

      expect(find.text('Necesitas iniciar sesión'), findsNothing);
      expect(find.byType(IncidentMapMarker), findsOneWidget);
    });

    testWidgets('Mi perfil shows the sign-in invitation and no logout', (tester) async {
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(find.text('Inicia sesión para ver tu perfil'), findsOneWidget);
      expect(find.byTooltip('Cerrar sesión'), findsNothing);

      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen Mock'), findsOneWidget);
    });
  });

  testWidgets('a map that cannot load shows the message and a retry button', (tester) async {
    cities = const [];
    await tester.pumpWidget(createShell());
    await tester.pumpAndSettle();


    expect(find.text('No pudimos cargar el mapa'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  group('city switcher (HU-21)', () {
    const pasto = City(
      id: 2,
      name: 'Pasto',
      department: 'Nariño',
      latitude: 1.2136,
      longitude: -77.2811,
      isCapital: true,
    );

    testWidgets('the map shows its city and the sheet changes it by search', (tester) async {
      cities = const [_cali, pasto];
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      expect(find.text('Cali, Valle del Cauca'), findsOneWidget);

      await tester.tap(find.text('Cali, Valle del Cauca'));
      await tester.pumpAndSettle();

      expect(find.text('Cambiar ciudad'), findsOneWidget);
      expect(find.widgetWithText(ActionChip, 'Cali'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'narino');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pasto, Nariño'));
      await tester.pumpAndSettle();

      expect(find.text('Cambiar ciudad'), findsNothing);
      expect(find.text('Pasto, Nariño'), findsOneWidget);
      expect(profiles.stored['uid-1']!.lastCityName, 'Pasto');
      expect(recents.names, ['Pasto']);
    });

    testWidgets('a search without matches says so', (tester) async {
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cali, Valle del Cauca'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.textContaining('No encontramos esa ciudad'), findsOneWidget);
    });

    testWidgets('a guest can switch city too, and nothing is saved in a profile', (tester) async {
      auth = FakeAuthRepository();
      cities = const [_cali, pasto];
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cali, Valle del Cauca'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'pasto');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pasto, Nariño'));
      await tester.pumpAndSettle();

      expect(find.text('Pasto, Nariño'), findsOneWidget);
      expect(profiles.calls.where((c) => c == 'profile.updateLastCity'), isEmpty);
    });
  });
}

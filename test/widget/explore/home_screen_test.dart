import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/theme/theme_cubit.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/open_location_settings_usecase.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_event.dart';
import 'package:vigia_app/features/explore/domain/usecases/get_city_options_usecase.dart';
import 'package:vigia_app/features/notifications/domain/usecases/enable_push_usecase.dart';
import 'package:vigia_app/features/notifications/domain/usecases/watch_opened_reports_usecase.dart';
import 'package:vigia_app/features/notifications/ui/bloc/push_bloc.dart';
import 'package:vigia_app/features/explore/domain/usecases/search_cities_usecase.dart';
import 'package:vigia_app/features/explore/ui/bloc/city_switcher_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_bloc.dart';
import 'package:vigia_app/features/explore/ui/widgets/feed_incident_card.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_city_feed_usecase.dart';
import 'package:vigia_app/features/explore/ui/bloc/map_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/map_event.dart';
import 'package:vigia_app/features/explore/ui/screens/home_screen.dart';
import 'package:vigia_app/features/explore/ui/widgets/incident_map_marker.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_marker.dart';
import 'package:vigia_app/features/explore/domain/usecases/switch_city_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_city_map_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_current_location_usecase.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../support/fake_push_repository.dart';
import '../../support/fakes.dart';
import '../../support/profile_bloc_factory.dart';
import '../../support/report_filter_samples.dart';

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

FeedIncident _feedReport(String title, {String id = 'inc-1'}) => FeedIncident(
      id: id,
      trackingCode: '#VIG-1001',
      title: title,
      neighborhood: 'Centro',
      categoryName: 'Hueco o bache en calzada',
      categoryIcon: 'warning',
      severity: IncidentSeverity.high,
      status: IncidentStatus.reported,
      coordinates: const Coordinates(latitude: 3.45, longitude: -76.53),
      createdAt: DateTime.utc(2026, 11, 14, 12),
    );

/// A location whose answer the test decides when to give, like a permission
/// dialog the citizen has not answered yet.
class _PendingLocationRepository extends FakeLocationRepository {
  final answer = Completer<Coordinates>();

  @override
  Future<Coordinates> currentCoordinates() => answer.future;
}

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
    incidents = FakeIncidentRepository()
      ..cityMarkers = [_marker]
      ..feed = [_feedReport('Hueco grande en la Cra 15')];
    cities = const [_cali];
    recents = FakeRecentCitiesRepository();
    location = FakeLocationRepository(coordinates: const Coordinates(latitude: 3.40, longitude: -76.55));
  });

  // Blocs are created inside each test so their event loop runs in the
  // tester's fake async zone.
  Widget createShell({FakePushRepository? push}) {
    final profileBloc = buildProfileBloc(auth, profiles)
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
    final feedBloc = FeedBloc(GetCityFeedUseCase(incidents));
    addTearDown(profileBloc.close);
    addTearDown(mapBloc.close);
    addTearDown(switcherBloc.close);
    addTearDown(feedBloc.close);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider<ProfileBloc>.value(value: profileBloc),
        BlocProvider<MapBloc>.value(value: mapBloc),
        BlocProvider<CitySwitcherBloc>.value(value: switcherBloc),
        BlocProvider<FeedBloc>.value(value: feedBloc),
        if (push != null)
          BlocProvider<PushBloc>(
            create: (_) => PushBloc(EnablePushUseCase(auth, push), WatchOpenedReportsUseCase(push)),
          ),
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

  testWidgets('the pushes wait for the location question: one permission dialog at a time', (tester) async {
    final pending = _PendingLocationRepository();
    location = pending;
    final push = FakePushRepository();

    await tester.pumpWidget(createShell(push: push));
    await tester.pump(const Duration(seconds: 1));

    expect(push.calls, isEmpty, reason: 'the location is still being asked');

    pending.answer.complete(const Coordinates(latitude: 3.40, longitude: -76.55));
    await tester.pumpAndSettle();

    expect(push.calls, ['push.enable uid-1']);
  });

  testWidgets('opens on Mapa with the bottom bar and the report button', (tester) async {
    await tester.pumpWidget(createShell());
    await tester.pumpAndSettle();

    expect(find.text('Mapa'), findsNWidgets(2)); // app bar title + tab label
    expect(find.byTooltip('Centrar en mi ubicación'), findsOneWidget);
    expect(find.text('Reportar daño'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.circleUserRound));
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

      await tester.tap(find.byIcon(LucideIcons.circleUserRound));
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

    testWidgets('choosing a city moves the camera there, even when the map opened on the citizen', (tester) async {
      cities = const [_cali, pasto];
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      final map = find.byType(FlutterMap);
      final before = tester.widget<FlutterMap>(map).mapController!.camera.center;
      expect(before.latitude, closeTo(3.40, 0.01)); // the citizen's position (permission granted)

      await tester.tap(find.text('Cali, Valle del Cauca'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'narino');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pasto, Nariño'));
      await tester.pumpAndSettle();

      final after = tester.widget<FlutterMap>(map).mapController!.camera.center;
      expect(after.latitude, closeTo(pasto.latitude, 0.001));
      expect(after.longitude, closeTo(pasto.longitude, 0.001));
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

  group('Comunidad tab (HU-19)', () {
    const pasto = City(
      id: 2,
      name: 'Pasto',
      department: 'Nariño',
      latitude: 1.2136,
      longitude: -77.2811,
      isCapital: true,
    );

    Future<void> openFeed(WidgetTester tester) async {
      await tester.tap(find.byIcon(LucideIcons.usersRound));
      await tester.pumpAndSettle();
    }

    testWidgets('is the second tab, between Mapa and Mi perfil', (tester) async {
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      expect(find.text('Comunidad'), findsOneWidget); // only the tab label for now

      await openFeed(tester);

      expect(find.text('Comunidad'), findsNWidgets(2)); // app bar title + tab label
      expect(find.text('Cali, Valle del Cauca'), findsWidgets);
      expect(find.text('Hueco grande en la Cra 15'), findsOneWidget);
      expect(find.byType(FeedIncidentCard), findsOneWidget);
    });

    testWidgets('lists the reports of the city the map resolved, without opening the tab first', (tester) async {
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      expect(incidents.calls, contains('incident.getCityFeed'));
      expect(incidents.lastCity, 'Cali');
    });

    testWidgets('changing the city on the map changes the feed', (tester) async {
      cities = const [_cali, pasto];
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();
      incidents.feed = [_feedReport('Bache en Pasto', id: 'inc-9')];

      await tester.tap(find.text('Cali, Valle del Cauca'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'pasto');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pasto, Nariño'));
      await tester.pumpAndSettle();

      expect(incidents.lastCity, 'Pasto');

      await openFeed(tester);

      expect(find.text('Bache en Pasto'), findsOneWidget);
      expect(find.text('Hueco grande en la Cra 15'), findsNothing);
    });

    testWidgets('a published report refreshes the feed', (tester) async {
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();
      incidents.feed = [_feedReport('Reporte recién publicado', id: 'inc-2')];

      await tester.tap(find.text('Reportar daño'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publicar'));
      await tester.pumpAndSettle();
      await openFeed(tester);

      expect(find.text('Reporte recién publicado'), findsOneWidget);
    });

    testWidgets('a cancelled wizard does not reload the feed', (tester) async {
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();
      final callsBefore = incidents.calls.where((c) => c == 'incident.getCityFeed').length;

      await tester.tap(find.text('Reportar daño'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(incidents.calls.where((c) => c == 'incident.getCityFeed').length, callsBefore);
    });

    testWidgets('a guest reads the feed too, and the empty state opens the sign-in modal', (tester) async {
      auth = FakeAuthRepository();
      location = FakeLocationRepository(error: Exception('Sin permiso de ubicación.'));
      incidents.feed = [];
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      await openFeed(tester);

      expect(find.text('Aún no hay reportes en Cali'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Reportar daño'));
      await tester.pumpAndSettle();

      expect(find.text('Necesitas iniciar sesión'), findsOneWidget);
      expect(find.text('Publicar'), findsNothing);
    });

    testWidgets('a guest sees the reports of their nearest city in the feed', (tester) async {
      auth = FakeAuthRepository();
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      await openFeed(tester);

      expect(find.text('Hueco grande en la Cra 15'), findsOneWidget);
    });
  });

  group('Search and filters across Comunidad and Mapa (HU-20)', () {
    /// Two reports in the city, as pins and as feed cards: a pothole and a traffic light.
    void stageTwoReports() {
      incidents
        ..cityMarkers = [
          filterMarker(id: 'inc-1', title: 'Hueco en la Calle 5', neighborhood: 'Centro'),
          filterMarker(
            id: 'inc-2',
            code: '#VIG-1002',
            title: 'Semáforo apagado',
            neighborhood: 'Granada',
            category: 'Semáforo dañado o apagado',
          ),
        ]
        ..feed = [
          filterFeedIncident(id: 'inc-1', title: 'Hueco en la Calle 5', neighborhood: 'Centro'),
          filterFeedIncident(
            id: 'inc-2',
            code: '#VIG-1002',
            title: 'Semáforo apagado',
            neighborhood: 'Granada',
            category: 'Semáforo dañado o apagado',
          ),
        ];
      // Permission denied on open: the map keeps the city view, where the pins are.
      location = FakeLocationRepository(error: Exception('Sin permiso de ubicación. Elige tu ciudad en la lista.'));
    }

    testWidgets('a filter set in Comunidad stays on the pins of Mapa and can be cleared there (criterion 5)',
        (tester) async {
      stageTwoReports();
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();
      expect(find.byType(IncidentMapMarker), findsNWidgets(2));

      await tester.tap(find.byIcon(LucideIcons.usersRound));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'semaforo');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.map));
      await tester.pumpAndSettle();

      expect(find.byType(IncidentMapMarker), findsOneWidget);
      expect(find.bySemanticsLabel('Semáforo apagado, Semáforo dañado o apagado, gravedad Alta'), findsOneWidget);
      expect(find.text('1 filtro activo: 1 de 2 reportes'), findsOneWidget);

      await tester.tap(find.text('Limpiar'));
      await tester.pumpAndSettle();

      expect(find.byType(IncidentMapMarker), findsNWidgets(2));
      expect(find.textContaining('filtro activo'), findsNothing);

      // Back in Comunidad the search is empty too: it is the same filter.
      await tester.tap(find.byIcon(LucideIcons.usersRound));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);
    });

    testWidgets('the neighborhood and the category chosen in Comunidad narrow the pins too (criterion 5)',
        (tester) async {
      stageTwoReports();
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.usersRound));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Barrio'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(ListTile), matching: find.text('Granada')));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.map));
      await tester.pumpAndSettle();

      expect(find.byType(IncidentMapMarker), findsOneWidget);
    });

    testWidgets('"Más cercanos" with a blocked permission opens the explanation and keeps the order (criterion 4)',
        (tester) async {
      stageTwoReports();
      location = FakeLocationRepository(error: Exception(LocationRepository.blockedMessage));
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.usersRound));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Más recientes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Más cercanos'));
      await tester.pumpAndSettle();

      expect(find.text('Ubicación bloqueada'), findsOneWidget);
      expect(find.textContaining('activa tu ubicación'), findsOneWidget);

      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect(find.text('Más recientes'), findsOneWidget, reason: 'the previous order stays');
    });

    testWidgets('"Más cercanos" locates the citizen when the first attempt was denied and then orders', (tester) async {
      stageTwoReports();
      location = FakeLocationRepository(
        coordinates: const Coordinates(latitude: 3.40, longitude: -76.55),
        firstCallError: Exception('Sin permiso de ubicación. Elige tu ciudad en la lista.'),
      );
      await tester.pumpWidget(createShell());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.usersRound));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Más recientes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Más cercanos'));
      await tester.pumpAndSettle();

      expect(find.text('Más cercanos'), findsOneWidget, reason: 'the chip names the new order');
      expect(find.textContaining('activa tu ubicación'), findsNothing);
    });
  });
}

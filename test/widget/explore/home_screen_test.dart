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
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/open_location_settings_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_event.dart';
import 'package:vigia_app/features/explore/ui/bloc/map_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/map_event.dart';
import 'package:vigia_app/features/explore/ui/screens/home_screen.dart';
import 'package:vigia_app/features/explore/ui/widgets/incident_map_marker.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_marker.dart';
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

  setUp(() {
    auth = FakeAuthRepository(user: const AuthUser(id: 'uid-1', email: 'ana@example.com'));
    profiles = FakeProfileRepository()
      ..stored['uid-1'] = const Profile(id: 'uid-1', email: 'ana@example.com', fullName: 'Ana Gomez', cityName: 'Cali');
    incidents = FakeIncidentRepository()..cityMarkers = [_marker];
    cities = const [_cali];
  });

  // Blocs are created inside each test so their event loop runs in the
  // tester's fake async zone.
  Widget createShell() {
    final profileBloc = ProfileBloc(GetCurrentProfileUseCase(auth, profiles), SignOutUseCase(auth))
      ..add(ProfileStarted());
    final location = FakeLocationRepository(coordinates: const Coordinates(latitude: 3.40, longitude: -76.55));
    final mapBloc = MapBloc(
      GetCityMapUseCase(auth, profiles, FakeCityRepository(cities), incidents),
      GetCurrentLocationUseCase(location),
      OpenLocationSettingsUseCase(location),
    )..add(MapStarted());
    addTearDown(profileBloc.close);
    addTearDown(mapBloc.close);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider<ProfileBloc>.value(value: profileBloc),
        BlocProvider<MapBloc>.value(value: mapBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const HomeScreen(),
        routes: {
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

  testWidgets('opens on Mi perfil with the bottom bar and the report button', (tester) async {
    await tester.pumpWidget(createShell());
    await tester.pumpAndSettle();

    expect(find.text('Ana Gomez'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Mi perfil'), findsNWidgets(2)); // app bar title + tab label
    expect(find.text('Reportar daño'), findsOneWidget);
  });

  testWidgets('the Mapa tab shows a marker per report of the city', (tester) async {
    await tester.pumpWidget(createShell());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump();

    expect(find.byType(IncidentMapMarker), findsOneWidget);
    expect(find.bySemanticsLabel('Hueco en la Calle 5, Hueco o bache en calzada, gravedad Alta'), findsOneWidget);
  });

  testWidgets('"Centrar en mi ubicación" shows the citizen on the map', (tester) async {
    await tester.pumpWidget(createShell());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump();

    expect(find.bySemanticsLabel('Tu ubicación'), findsNothing);

    await tester.tap(find.byTooltip('Centrar en mi ubicación'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Tu ubicación'), findsOneWidget);
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

  testWidgets('a map that cannot load shows the message and a retry button', (tester) async {
    cities = const [];
    await tester.pumpWidget(createShell());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump();

    expect(find.text('No pudimos cargar el mapa'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });
}

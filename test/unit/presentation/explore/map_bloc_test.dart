import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/open_location_settings_usecase.dart';
import 'package:vigia_app/features/explore/ui/bloc/map_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/map_event.dart';
import 'package:vigia_app/features/explore/ui/bloc/map_state.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_marker.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_city_map_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_current_location_usecase.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/fakes.dart';

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
  title: 'Semáforo apagado',
  categoryName: 'Semáforo dañado o apagado',
  categoryIcon: 'traffic',
  severity: IncidentSeverity.critical,
  coordinates: Coordinates(latitude: 3.45, longitude: -76.53),
);

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeIncidentRepository incidents;
  late FakeLocationRepository location;

  MapBloc buildBloc() {
    final bloc = MapBloc(
      GetCityMapUseCase(auth, profiles, FakeCityRepository(const [_cali]), incidents),
      GetCurrentLocationUseCase(location),
      OpenLocationSettingsUseCase(location),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  setUp(() {
    auth = FakeAuthRepository(user: const AuthUser(id: 'uid-1', email: 'ana@example.com'));
    profiles = FakeProfileRepository()
      ..stored['uid-1'] = const Profile(id: 'uid-1', email: 'ana@example.com', fullName: 'Ana Gomez', cityName: 'Cali');
    incidents = FakeIncidentRepository()..cityMarkers = [_marker];
    location = FakeLocationRepository(coordinates: const Coordinates(latitude: 3.40, longitude: -76.55));
  });

  test('starts empty', () {
    final bloc = buildBloc();

    expect(bloc.state.status, MapStatus.initial);
    expect(bloc.state.city, isNull);
    expect(bloc.state.markers, isEmpty);
  });

  test('MapStarted emits loading and then the city with its markers', () async {
    location = FakeLocationRepository(permissionGranted: false);

    final states = await emittedStates(buildBloc(), MapStarted());

    expect(states.map((s) => s.status), [MapStatus.loading, MapStatus.success]);
    expect(states.last.city, _cali);
    expect(states.last.markers, [_marker]);
  });

  test('with the permission already granted, MapStarted also finds the citizen', () async {
    final states = await emittedStates(buildBloc(), MapStarted());

    expect(states.last.status, MapStatus.success);
    expect(states.last.myLocationStatus, MyLocationStatus.found);
    expect(states.last.myLocation?.latitude, 3.40);
  });

  test('without the permission, MapStarted stays silent: no dialog, no error', () async {
    location = FakeLocationRepository(permissionGranted: false);

    final states = await emittedStates(buildBloc(), MapStarted());

    expect(states.last.myLocationStatus, MyLocationStatus.idle);
    expect(states.last.myLocationMessage, isNull);
  });

  test('a blocked permission on open does not trigger the blocked modal', () async {
    location = FakeLocationRepository(error: Exception(LocationRepository.blockedMessage));

    final states = await emittedStates(buildBloc(), MapStarted());

    expect(states.last.status, MapStatus.success);
    expect(states.last.myLocationStatus, MyLocationStatus.idle);
  });

  test('MapStarted emits the error message when the map cannot load', () async {
    auth = FakeAuthRepository();

    final states = await emittedStates(buildBloc(), MapStarted());

    expect(states.last.status, MapStatus.failure);
    expect(states.last.errorMessage, 'Inicia sesión para ver el mapa.');
  });

  group('MyLocationRequested', () {
    test('emits locating and then the position', () async {
      final states = await emittedStates(buildBloc(), MyLocationRequested());

      expect(states.map((s) => s.myLocationStatus), [MyLocationStatus.locating, MyLocationStatus.found]);
      expect(states.last.myLocation?.latitude, 3.40);
      expect(states.last.myLocationMessage, isNull);
    });

    test('a blocked permission emits blocked with its message', () async {
      location = FakeLocationRepository(error: Exception(LocationRepository.blockedMessage));

      final states = await emittedStates(buildBloc(), MyLocationRequested());

      expect(states.last.myLocationStatus, MyLocationStatus.blocked);
      expect(states.last.myLocationMessage, LocationRepository.blockedMessage);
    });

    test('any other error emits failure and keeps the map loaded', () async {
      location = FakeLocationRepository(error: Exception('La ubicación está desactivada.'));
      final bloc = buildBloc();
      await emittedStates(bloc, MapStarted());

      final states = await emittedStates(bloc, MyLocationRequested());

      expect(states.last.myLocationStatus, MyLocationStatus.failure);
      expect(states.last.myLocationMessage, 'La ubicación está desactivada.');
      expect(states.last.markers, [_marker]);
    });
  });

  test('LocationSettingsRequested opens the system settings', () async {
    await emittedStates(buildBloc(), LocationSettingsRequested());

    expect(location.openSettingsCalls, 1);
  });
}

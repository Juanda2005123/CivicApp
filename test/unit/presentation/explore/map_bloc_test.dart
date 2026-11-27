import 'dart:async';

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
import 'package:vigia_app/features/explore/domain/usecases/switch_city_usecase.dart';
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

/// A permission request the system never answers.
class _SilentLocationRepository extends FakeLocationRepository {
  @override
  Future<Coordinates> currentCoordinates() => Completer<Coordinates>().future;
}

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeIncidentRepository incidents;
  late FakeLocationRepository location;

  MapBloc buildBloc() {
    final bloc = MapBloc(
      GetCityMapUseCase(auth, profiles, FakeCityRepository(const [_cali]), incidents, location),
      GetCurrentLocationUseCase(location),
      OpenLocationSettingsUseCase(location),
      SwitchCityUseCase(auth, profiles, FakeRecentCitiesRepository()),
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
    location = FakeLocationRepository(error: Exception('Sin permiso de ubicación. Elige tu ciudad en la lista.'));

    final states = await emittedStates(buildBloc(), MapStarted());

    expect(states.map((s) => s.status), [MapStatus.loading, MapStatus.success]);
    expect(states.last.city, _cali);
    expect(states.last.markers, [_marker]);
  });

  test('MapStarted asks for the location once and centers on the citizen (HU-03)', () async {
    final states = await emittedStates(buildBloc(), MapStarted());

    expect(location.calls, 1);
    expect(states.last.status, MapStatus.success);
    expect(states.last.myLocationStatus, MyLocationStatus.found);
    expect(states.last.myLocation?.latitude, 3.40);
  });

  test('denying the permission on open stays silent: city view, no error', () async {
    location = FakeLocationRepository(error: Exception('Sin permiso de ubicación. Elige tu ciudad en la lista.'));

    final states = await emittedStates(buildBloc(), MapStarted());

    expect(states.last.status, MapStatus.success);
    expect(states.last.myLocationStatus, MyLocationStatus.idle);
    expect(states.last.myLocationMessage, isNull);
  });

  test('a reload after publishing does not ask for the location again', () async {
    final bloc = buildBloc();
    await emittedStates(bloc, MapStarted());

    await emittedStates(bloc, MapStarted());

    expect(location.calls, 1);
  });

  test('a blocked permission on open does not trigger the blocked modal', () async {
    location = FakeLocationRepository(error: Exception(LocationRepository.blockedMessage));

    final states = await emittedStates(buildBloc(), MapStarted());

    expect(states.last.status, MapStatus.success);
    expect(states.last.myLocationStatus, MyLocationStatus.idle);
  });

  test('MapStarted emits the error message when the map cannot load', () async {
    profiles.stored['uid-1'] = const Profile(id: 'uid-1', email: 'ana@example.com', fullName: 'Ana Gomez', cityName: 'Tumaco');
    // Without a position the profile decides, and Tumaco is not in the catalog.
    location = FakeLocationRepository(error: Exception('Sin permiso de ubicación.'));

    final states = await emittedStates(buildBloc(), MapStarted());

    expect(states.last.status, MapStatus.failure);
    expect(states.last.errorMessage, 'No encontramos tu ciudad en el mapa.');
  });

  test('a citizen in another covered city opens on it, and the map centers on them (HU-13)', () async {
    profiles.stored['uid-1'] = const Profile(id: 'uid-1', email: 'ana@example.com', fullName: 'Ana Gomez', cityName: 'Pasto');
    location = FakeLocationRepository(coordinates: const Coordinates(latitude: 3.45, longitude: -76.53));

    final states = await emittedStates(buildBloc(), MapStarted());

    expect(states.last.city, _cali);
    expect(states.last.myLocationStatus, MyLocationStatus.found);
    expect(location.calls, 1); // one read: the permission is asked once
  });

  test('outside coverage the map keeps the profile city and does not jump to the citizen (HU-13)', () async {
    location = FakeLocationRepository(coordinates: const Coordinates(latitude: 4.71, longitude: -74.07));

    final states = await emittedStates(buildBloc(), MapStarted());

    expect(states.last.city, _cali); // the profile city
    expect(states.last.myLocationStatus, MyLocationStatus.idle);
    expect(states.last.myLocation, isNull);
  });

  test('a position that never arrives does not leave the map loading', () async {
    final bloc = MapBloc(
      GetCityMapUseCase(auth, profiles, FakeCityRepository(const [_cali]), incidents, location),
      GetCurrentLocationUseCase(_SilentLocationRepository()),
      OpenLocationSettingsUseCase(location),
      SwitchCityUseCase(auth, profiles, FakeRecentCitiesRepository()),
      locationWait: const Duration(milliseconds: 20),
    );
    addTearDown(bloc.close);

    bloc.add(MapStarted());
    final state = await bloc.stream.firstWhere((state) => state.status != MapStatus.loading);

    expect(state.status, MapStatus.success);
    expect(state.city, _cali); // the profile city
    expect(state.markers, [_marker]);
    expect(state.myLocation, isNull);
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

  group('CitySelected (HU-21)', () {
    const pasto = City(
      id: 2,
      name: 'Pasto',
      department: 'Nariño',
      latitude: 1.2136,
      longitude: -77.2811,
      isCapital: true,
    );

    test('saves the city and shows its markers', () async {
      final bloc = buildBloc();
      await emittedStates(bloc, MapStarted());

      final states = await emittedStates(bloc, CitySelected(pasto));

      expect(states.map((s) => s.status), [MapStatus.loading, MapStatus.success]);
      expect(states.last.city, pasto);
      expect(incidents.lastCity, 'Pasto');
      expect(profiles.stored['uid-1']!.lastCityName, 'Pasto');
    });

    test('a reload keeps the city the citizen picked', () async {
      final bloc = buildBloc();
      await emittedStates(bloc, MapStarted());
      await emittedStates(bloc, CitySelected(pasto));

      final states = await emittedStates(bloc, MapStarted());

      expect(states.last.city, pasto);
    });

    test('when saving fails the map keeps the previous city and says why', () async {
      final bloc = buildBloc();
      await emittedStates(bloc, MapStarted());
      profiles.updateLastCityError = Exception('No pudimos guardar tu ciudad.');

      final states = await emittedStates(bloc, CitySelected(pasto));

      expect(states.last.status, MapStatus.failure);
      expect(states.last.errorMessage, 'No pudimos guardar tu ciudad.');
      expect(states.last.city, _cali);
      expect(states.last.markers, [_marker]);
    });
  });
}

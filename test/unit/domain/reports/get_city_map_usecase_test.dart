import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_marker.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_city_map_usecase.dart';

import '../../../support/fakes.dart';

const _cali = City(
  id: 1,
  name: 'Cali',
  department: 'Valle del Cauca',
  latitude: 3.4516,
  longitude: -76.5320,
  isCapital: true,
);
const _pasto = City(
  id: 2,
  name: 'Pasto',
  department: 'Nariño',
  latitude: 1.2136,
  longitude: -77.2811,
  isCapital: true,
);
const _pothole = IncidentMarker(
  id: 'inc-1',
  trackingCode: '#VIG-1001',
  title: 'Hueco en la Calle 5',
  categoryName: 'Hueco o bache en calzada',
  categoryIcon: 'warning',
  severity: IncidentSeverity.high,
  coordinates: Coordinates(latitude: 3.42, longitude: -76.54),
);

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeIncidentRepository incidents;
  late FakeLocationRepository location;

  GetCityMapUseCase useCase({List<City> cities = const [_cali, _pasto]}) =>
      GetCityMapUseCase(auth, profiles, FakeCityRepository(cities), incidents, location);

  setUp(() {
    auth = FakeAuthRepository(user: const AuthUser(id: 'uid-1', email: 'ana@example.com'));
    profiles = FakeProfileRepository()
      ..stored['uid-1'] = const Profile(id: 'uid-1', email: 'ana@example.com', fullName: 'Ana Gomez', cityName: 'Pasto');
    incidents = FakeIncidentRepository()..cityMarkers = [_pothole];
    location = FakeLocationRepository(coordinates: const Coordinates(latitude: 1.22, longitude: -77.28));
  });

  test('returns the profile city and the reports of that city', () async {
    final (city, markers) = await useCase()();

    expect(city, _pasto);
    expect(markers, [_pothole]);
    expect(incidents.lastCity, 'Pasto');
  });

  test('resolved reports are left off the map (HU-25)', () async {
    const repaired = IncidentMarker(
      id: 'inc-2',
      trackingCode: '#VIG-1002',
      title: 'Hueco ya tapado',
      categoryName: 'Hueco o bache en calzada',
      categoryIcon: 'warning',
      severity: IncidentSeverity.medium,
      coordinates: Coordinates(latitude: 3.43, longitude: -76.53),
      status: IncidentStatus.resolved,
    );
    incidents.cityMarkers = [_pothole, repaired];

    final (_, markers) = await useCase()();

    expect(markers, [_pothole]);
  });

  test('a guest sees the city nearest to the GPS (HU-22)', () async {
    auth = FakeAuthRepository();

    final (city, markers) = await useCase()();

    expect(city, _pasto);
    expect(markers, [_pothole]);
    expect(incidents.lastCity, 'Pasto');
  });

  test('a guest without GPS starts on the fallback city', () async {
    auth = FakeAuthRepository();
    location = FakeLocationRepository(error: Exception('Sin permiso de ubicación.'));

    final (city, _) = await useCase()();

    expect(city.name, GetCityMapUseCase.guestFallbackCity);
  });

  // Registered in Pasto, standing in Cali.
  const inCali = Coordinates(latitude: 3.45, longitude: -76.53);

  test('a signed-in citizen standing in another covered city sees that city (HU-13)', () async {
    final (city, markers) = await useCase()(position: inCali, positionRead: true);

    expect(city, _cali);
    expect(markers, [_pothole]);
    expect(incidents.lastCity, 'Cali');
  });

  test('being in another city does not touch the saved last city (HU-21)', () async {
    await useCase()(position: inCali, positionRead: true);

    expect(profiles.stored['uid-1']!.lastCityName, 'Pasto');
  });

  test('without a position the signed-in citizen keeps the last city of the profile', () async {
    final (city, _) = await useCase()(positionRead: true);

    expect(city, _pasto);
  });

  test('outside coverage the signed-in citizen keeps the last city of the profile', () async {
    // Bogotá is not in the catalog used here and is far from Cali and Pasto.
    const bogota = Coordinates(latitude: 4.71, longitude: -74.07);

    final (city, _) = await useCase()(position: bogota, positionRead: true);

    expect(city, _pasto);
  });

  test('the use case never reads the GPS itself once the caller did', () async {
    await useCase()(positionRead: true);
    auth = FakeAuthRepository();
    await useCase()(positionRead: true);

    expect(location.calls, 0);
  });

  test('covers() tells whether a position is inside the coverage of a city', () {
    expect(GetCityMapUseCase.covers(_cali, inCali), isTrue);
    expect(GetCityMapUseCase.covers(_cali, const Coordinates(latitude: 4.71, longitude: -74.07)), isFalse);
  });

  test('a profile city missing from the catalog gives a clear message', () async {
    await expectLater(
      useCase(cities: const [_cali])(),
      throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('No encontramos tu ciudad'))),
    );
    expect(incidents.calls, isEmpty);
  });

  test('opens on the last city of the profile, not on the reference city (HU-21)', () async {
    profiles.stored['uid-1'] = const Profile(
      id: 'uid-1',
      email: 'ana@example.com',
      fullName: 'Ana Gomez',
      cityName: 'Pasto',
      lastCityName: 'Cali',
    );

    final (city, _) = await useCase()(positionRead: true);

    expect(city, _cali);
  });

  test('a city chosen on the switcher skips the profile and the GPS', () async {
    final (city, markers) = await useCase()(city: _cali);

    expect(city, _cali);
    expect(markers, [_pothole]);
    expect(incidents.lastCity, 'Cali');
    expect(profiles.calls, isEmpty);
    expect(location.calls, 0);
  });
}

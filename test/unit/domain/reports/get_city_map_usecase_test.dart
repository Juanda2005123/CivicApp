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

  GetCityMapUseCase useCase({List<City> cities = const [_cali, _pasto]}) =>
      GetCityMapUseCase(auth, profiles, FakeCityRepository(cities), incidents);

  setUp(() {
    auth = FakeAuthRepository(user: const AuthUser(id: 'uid-1', email: 'ana@example.com'));
    profiles = FakeProfileRepository()
      ..stored['uid-1'] = const Profile(id: 'uid-1', email: 'ana@example.com', fullName: 'Ana Gomez', cityName: 'Pasto');
    incidents = FakeIncidentRepository()..cityMarkers = [_pothole];
  });

  test('returns the profile city and the reports of that city', () async {
    final (city, markers) = await useCase()();

    expect(city, _pasto);
    expect(markers, [_pothole]);
    expect(incidents.lastCity, 'Pasto');
  });

  test('without a session it fails before querying reports', () async {
    auth = FakeAuthRepository();

    await expectLater(useCase()(), throwsA(isA<Exception>()));
    expect(incidents.calls, isEmpty);
  });

  test('a profile city missing from the catalog gives a clear message', () async {
    await expectLater(
      useCase(cities: const [_cali])(),
      throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('No encontramos tu ciudad'))),
    );
    expect(incidents.calls, isEmpty);
  });
}

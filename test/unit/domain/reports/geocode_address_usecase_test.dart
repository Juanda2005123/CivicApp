import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/location_source.dart';
import 'package:vigia_app/features/reports/domain/usecases/geocode_address_usecase.dart';

import '../../../support/fakes.dart';

const _popayan = City(
  id: 1,
  name: 'Popayán',
  department: 'Cauca',
  latitude: 2.4448,
  longitude: -76.6147,
  isCapital: true,
);
const _center = Coordinates(latitude: 2.4448, longitude: -76.6147);
const _house = Coordinates(latitude: 2.4423, longitude: -76.6091);
const _street = Coordinates(latitude: 2.4400, longitude: -76.6050);
const _otherCity = Coordinates(latitude: 3.4516, longitude: -76.5320); // Cali, 110 km away
const _madrid = Coordinates(latitude: 40.4168, longitude: -3.7038);

const _withPlate = 'Carrera 9 # 5-45, El Modelo, Popayán, Colombia';
const _streetOnly = 'Carrera 9, El Modelo, Popayán, Colombia';

/// [Coordinates] has no value equality: compare the numbers.
Matcher _isPoint(Coordinates point) => isA<Coordinates>()
    .having((c) => c.latitude, 'latitude', point.latitude)
    .having((c) => c.longitude, 'longitude', point.longitude);

void main() {
  late FakeGeocodingRepository geocoding;

  GeocodeAddressUseCase useCase({List<City> cities = const [_popayan]}) =>
      GeocodeAddressUseCase(geocoding, FakeCityRepository(cities));

  Future<dynamic> locate({String address = 'Carrera 9 # 5 - 45', String neighborhood = 'El Modelo'}) =>
      useCase()(address: address, neighborhood: neighborhood, city: 'Popayán');

  setUp(() => geocoding = FakeGeocodingRepository());

  test('the building is the first search, and its point is used', () async {
    geocoding.addressResults[_withPlate] = _house;

    final location = await locate();

    expect(location.coordinates, _isPoint(_house));
    expect(location.source, LocationSource.address);
    expect(geocoding.addressQueries, [_withPlate]);
  });

  test('when the plate is not mapped it falls back to the road in the neighborhood', () async {
    geocoding.addressResults[_streetOnly] = _street;

    final location = await locate();

    expect(location.coordinates, _isPoint(_street));
    expect(location.source, LocationSource.address);
    expect(geocoding.addressQueries, [_withPlate, _streetOnly]);
  });

  test('typed abbreviations reach the service in full', () async {
    geocoding.addressResults[_withPlate] = _house;

    await locate(address: 'cra. 9 No. 5-45');

    expect(geocoding.addressQueries.first, _withPlate);
  });

  test('a match in another city is discarded: the same street name exists everywhere', () async {
    geocoding.addressResults[_withPlate] = _otherCity;
    geocoding.addressResults[_streetOnly] = _street;

    final location = await locate();

    expect(location.coordinates, _isPoint(_street));
    expect(geocoding.addressQueries, [_withPlate, _streetOnly]);
  });

  test('a match outside Colombia is discarded (RN-12)', () async {
    geocoding.addressResults[_withPlate] = _madrid;
    geocoding.addressResults[_streetOnly] = _street;

    expect((await locate()).coordinates, _isPoint(_street));
  });

  test('nothing found gives the center of the city, so the citizen is never blocked', () async {
    final location = await locate();

    expect(location.coordinates, _isPoint(_center));
    expect(location.source, LocationSource.cityCenter);
    expect(location.isCityCenter, isTrue);
    expect(geocoding.addressQueries, [_withPlate, _streetOnly]);
  });

  test('only far matches also give the center of the city', () async {
    geocoding.addressResults[_withPlate] = _otherCity;
    geocoding.addressResults[_streetOnly] = _otherCity;

    expect((await locate()).isCityCenter, isTrue);
  });

  test('a service that fails (offline, slow) gives the center of the city too', () async {
    geocoding.addressError = Exception('Sin conexión para buscar la dirección.');

    final location = await locate();

    expect(location.coordinates, _isPoint(_center));
    expect(location.isCityCenter, isTrue);
  });

  test('a reference point is searched as written', () async {
    geocoding.addressResults['Parque Caldas, El Modelo, Popayán, Colombia'] = _street;

    final location = await locate(address: 'Parque Caldas');

    expect(location.coordinates, _isPoint(_street));
    expect(location.source, LocationSource.address);
  });

  test('a city missing from the catalog is a clear error, before any search', () async {
    await expectLater(
      useCase(cities: const [])(address: 'Carrera 9 # 5-45', neighborhood: 'Centro', city: 'Popayán'),
      throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('No encontramos tu ciudad'))),
    );
    expect(geocoding.addressQueries, isEmpty);
  });

  test('an address that is not valid is rejected before any search', () async {
    await expectLater(locate(address: 'abc'), throwsException);
    expect(geocoding.addressQueries, isEmpty);
  });
}

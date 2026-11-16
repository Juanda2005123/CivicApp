import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/address_match.dart';
import 'package:vigia_app/features/reports/domain/entities/address_outcome.dart';
import 'package:vigia_app/features/reports/domain/entities/location_source.dart';
import 'package:vigia_app/features/reports/domain/usecases/geocode_address_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_city_center_usecase.dart';

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
const _building = AddressMatch(coordinates: Coordinates(latitude: 2.4423, longitude: -76.6091), isStreetOnly: false);
const _street = AddressMatch(coordinates: Coordinates(latitude: 2.4400, longitude: -76.6050), isStreetOnly: true);
const _otherCity = AddressMatch(coordinates: Coordinates(latitude: 3.4516, longitude: -76.5320), isStreetOnly: true);
const _madrid = AddressMatch(coordinates: Coordinates(latitude: 40.4168, longitude: -3.7038), isStreetOnly: true);

const _withPlate = 'Carrera 9 # 5-45, El Modelo, Popayán, Colombia';
const _streetOnly = 'Carrera 9, El Modelo, Popayán, Colombia';

/// [Coordinates] has no value equality: compare the numbers.
Matcher _isPoint(Coordinates point) => isA<Coordinates>()
    .having((c) => c.latitude, 'latitude', point.latitude)
    .having((c) => c.longitude, 'longitude', point.longitude);

void main() {
  late FakeGeocodingRepository geocoding;

  GeocodeAddressUseCase useCase({List<City> cities = const [_popayan]}) =>
      GeocodeAddressUseCase(geocoding, GetCityCenterUseCase(FakeCityRepository(cities)));

  Future<dynamic> locate({String address = 'Carrera 9 # 5 - 45', String neighborhood = 'El Modelo'}) =>
      useCase()(address: address, neighborhood: neighborhood, city: 'Popayán');

  setUp(() => geocoding = FakeGeocodingRepository());

  group('found', () {
    test('a building: the plate is the first search and its point is used', () async {
      geocoding.addressResults[_withPlate] = _building;

      final location = await locate();

      expect(location.coordinates, _isPoint(_building.coordinates));
      expect(location.outcome, AddressOutcome.building);
      expect(location.source, LocationSource.address);
      expect(location.isCityCenter, isFalse);
      expect(geocoding.addressQueries, [_withPlate]);
    });

    test('only the street: the point is along the road', () async {
      geocoding.addressResults[_withPlate] = _street;

      expect((await locate()).outcome, AddressOutcome.street);
    });

    test('when the plate finds nothing it falls back to the road in the neighborhood', () async {
      geocoding.addressResults[_streetOnly] = _street;

      final location = await locate();

      expect(location.coordinates, _isPoint(_street.coordinates));
      expect(location.outcome, AddressOutcome.street);
      expect(geocoding.addressQueries, [_withPlate, _streetOnly]);
    });

    test('typed abbreviations reach the service in full', () async {
      geocoding.addressResults[_withPlate] = _building;

      await locate(address: 'cra. 9 No. 5-45');

      expect(geocoding.addressQueries.first, _withPlate);
    });

    test('an address without # (Cra 9 5-45) is understood too', () async {
      geocoding.addressResults[_withPlate] = _building;

      expect((await locate(address: 'Cra 9 5-45')).outcome, AddressOutcome.building);
    });

    test('a reference point is searched as written', () async {
      geocoding.addressResults['Parque Caldas, El Modelo, Popayán, Colombia'] = _street;

      expect((await locate(address: 'Parque Caldas')).outcome, AddressOutcome.street);
    });
  });

  group('not usable matches', () {
    test('a match in another city is discarded: the same street name exists everywhere', () async {
      geocoding.addressResults[_withPlate] = _otherCity;
      geocoding.addressResults[_streetOnly] = _street;

      final location = await locate();

      expect(location.coordinates, _isPoint(_street.coordinates));
      expect(geocoding.addressQueries, [_withPlate, _streetOnly]);
    });

    test('a match outside Colombia is discarded (RN-12)', () async {
      geocoding.addressResults[_withPlate] = _madrid;
      geocoding.addressResults[_streetOnly] = _street;

      expect((await locate()).coordinates, _isPoint(_street.coordinates));
    });

    test('only far matches end as not found, on the city center', () async {
      geocoding.addressResults[_withPlate] = _otherCity;
      geocoding.addressResults[_streetOnly] = _otherCity;

      final location = await locate();

      expect(location.outcome, AddressOutcome.notFound);
      expect(location.coordinates, _isPoint(_center));
    });
  });

  group('city center', () {
    test('nothing found: the center of the city, so the citizen is never blocked', () async {
      final location = await locate();

      expect(location.coordinates, _isPoint(_center));
      expect(location.outcome, AddressOutcome.notFound);
      expect(location.source, LocationSource.cityCenter);
      expect(location.isCityCenter, isTrue);
      expect(geocoding.addressQueries, [_withPlate, _streetOnly]);
    });

    test('a service that fails says so, and stops after the first query', () async {
      geocoding.addressError = Exception('Sin conexión para buscar la dirección.');

      final location = await locate();

      expect(location.outcome, AddressOutcome.serviceFailed);
      expect(location.coordinates, _isPoint(_center));
      expect(geocoding.addressQueries, [_withPlate]);
    });

    test('text that looks like an address but is not understood says how it was read', () async {
      final location = await locate(address: 'Carrera 9 con Calle 5');

      expect(location.outcome, AddressOutcome.notUnderstood);
      expect(location.isCityCenter, isTrue);
    });

    test('a reference point that finds nothing is plain "not found"', () async {
      expect((await locate(address: 'Frente al parque Caldas')).outcome, AddressOutcome.notFound);
    });
  });

  group('errors', () {
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
  });
}

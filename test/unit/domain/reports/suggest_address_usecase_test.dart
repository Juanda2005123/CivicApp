import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/geocoded_place.dart';
import 'package:vigia_app/features/reports/domain/entities/suggested_address.dart';
import 'package:vigia_app/features/reports/domain/usecases/suggest_address_usecase.dart';

import '../../../support/fakes.dart';

void main() {
  group('SuggestAddressUseCase.parse', () {
    test('splits the street into road type and number, and the plate into cross and plot', () {
      final suggestion = SuggestAddressUseCase.parse(
        const GeocodedPlace(road: 'Calle 12', houseNumber: '5-37', neighborhood: 'San Pedro'),
      );

      expect(
        suggestion,
        const SuggestedAddress(roadType: 'Calle', mainRoad: '12', crossRoad: '5', plot: '37', neighborhood: 'San Pedro'),
      );
    });

    test('keeps letters and suffixes of the road number', () {
      expect(SuggestAddressUseCase.parse(const GeocodedPlace(road: 'Calle 10A Bis')).mainRoad, '10A Bis');
      expect(SuggestAddressUseCase.parse(const GeocodedPlace(road: 'Carrera 9 Norte')).mainRoad, '9 Norte');
    });

    test('understands common abbreviations of the road type', () {
      expect(SuggestAddressUseCase.parse(const GeocodedPlace(road: 'Cra. 15')).roadType, 'Carrera');
      expect(SuggestAddressUseCase.parse(const GeocodedPlace(road: 'Av 6N')).roadType, 'Avenida');
      expect(SuggestAddressUseCase.parse(const GeocodedPlace(road: 'Dg 23')).roadType, 'Diagonal');
    });

    test('a street outside the nomenclature only suggests the neighborhood', () {
      final suggestion = SuggestAddressUseCase.parse(
        const GeocodedPlace(road: 'Vía al Mar', houseNumber: '5-37', neighborhood: 'Dapa'),
      );

      expect(suggestion, const SuggestedAddress(neighborhood: 'Dapa'));
    });

    test('a plate that is not "cross-number" is ignored', () {
      final suggestion = SuggestAddressUseCase.parse(const GeocodedPlace(road: 'Calle 5', houseNumber: '120'));

      expect(suggestion.crossRoad, isNull);
      expect(suggestion.plot, isNull);
      expect(suggestion.mainRoad, '5');
    });

    test('accepts a plate written with a typographic dash', () {
      final suggestion = SuggestAddressUseCase.parse(const GeocodedPlace(road: 'Carrera 37A', houseNumber: '5 – 27'));

      expect(suggestion.crossRoad, '5');
      expect(suggestion.plot, '27');
    });

    test('an empty answer suggests nothing', () {
      expect(SuggestAddressUseCase.parse(const GeocodedPlace()), const SuggestedAddress());
    });
  });

  // A point on Calle 10A Bis in Cali (east-west). Its line ends at the corner
  // with Carrera 67A, about 30 m west of the point.
  const point = Coordinates(latitude: 3.3961, longitude: -76.5420);
  const calleLine = [
    Coordinates(latitude: 3.3961, longitude: -76.5423), // corner with Carrera 67A
    Coordinates(latitude: 3.3961, longitude: -76.5400), // corner with Carrera 68
  ];

  group('SuggestAddressUseCase.probePoints', () {
    test('places four probes beside the road, 30 m ahead of and behind the point on each side', () {
      final probes = SuggestAddressUseCase.probePoints(point, calleLine);

      // On an east-west road: 30 m north or south of it, 30 m east or west of
      // the point (1 m ≈ 0.000009°).
      const offset = 30 / 111320;
      final cosLat = cos(point.latitude * pi / 180);
      expect(probes, hasLength(4));
      for (final probe in probes) {
        expect((probe.latitude - point.latitude).abs(), closeTo(offset, 0.000001));
        expect((probe.longitude - point.longitude).abs(), closeTo(offset / cosLat, 0.000001));
      }
      expect({for (final probe in probes) (probe.latitude, probe.longitude)}, hasLength(4));
    });

    test('measures from the place on the road closest to the point, not from a vertex', () {
      // 10 m north of the road, far from both of its vertices.
      const aside = Coordinates(latitude: 3.3961 + 10 / 111320, longitude: -76.5410);

      final probes = SuggestAddressUseCase.probePoints(aside, calleLine);

      for (final probe in probes) {
        expect((probe.latitude - 3.3961).abs(), closeTo(30 / 111320, 0.000001));
      }
    });

    test('a path without direction gives no probes', () {
      expect(SuggestAddressUseCase.probePoints(point, const [Coordinates(latitude: 3.3961, longitude: -76.5423)]), isEmpty);
    });
  });

  group('SuggestAddressUseCase.crossRoadFrom', () {
    test('on a Calle only a Carrera or Transversal crosses it', () {
      expect(SuggestAddressUseCase.crossRoadFrom('Calle', '10A Bis', 'Carrera 67A'), '67A');
      expect(SuggestAddressUseCase.crossRoadFrom('Calle', '10A Bis', 'Transversal 4'), '4');
      expect(SuggestAddressUseCase.crossRoadFrom('Calle', '10A Bis', 'Calle 10A'), isNull);
    });

    test('on a Carrera only a Calle or Diagonal crosses it', () {
      expect(SuggestAddressUseCase.crossRoadFrom('Carrera', '5', 'Calle 12'), '12');
      expect(SuggestAddressUseCase.crossRoadFrom('Carrera', '5', 'Carrera 4'), isNull);
    });

    test('never the main road itself, nor names outside the nomenclature', () {
      expect(SuggestAddressUseCase.crossRoadFrom('Avenida', '6N', 'Avenida 6N'), isNull);
      expect(SuggestAddressUseCase.crossRoadFrom('Avenida', '6N', 'Calle 25'), '25');
      expect(SuggestAddressUseCase.crossRoadFrom('Calle', '12', 'Plaza de Cayzedo'), isNull);
      expect(SuggestAddressUseCase.crossRoadFrom('Calle', '12', null), isNull);
    });
  });

  group('SuggestAddressUseCase cross street lookup', () {
    test('without a plate it probes beside the road until a crossing street answers', () async {
      final geocoding = FakeGeocodingRepository(
        place: const GeocodedPlace(road: 'Calle 10A Bis', neighborhood: 'El Gran Limonar', roadPath: calleLine),
        streetAnswers: const [GeocodedPlace(road: 'Plaza de Cayzedo'), GeocodedPlace(road: 'Carrera 67A')],
      );

      final suggestion = await SuggestAddressUseCase(geocoding)(point).last;

      expect(geocoding.streetQueries, hasLength(2)); // the two probes, the line came with the address
      expect(
        suggestion,
        const SuggestedAddress(roadType: 'Calle', mainRoad: '10A Bis', crossRoad: '67A', neighborhood: 'El Gran Limonar'),
      );
    });

    test('answers the address first and the cross street afterwards', () async {
      final geocoding = FakeGeocodingRepository(
        place: const GeocodedPlace(road: 'Calle 10A Bis', roadPath: calleLine),
        streetAnswers: const [GeocodedPlace(road: 'Carrera 67A')],
      );

      final suggestions = await SuggestAddressUseCase(geocoding)(point).toList();

      expect(suggestions, const [
        SuggestedAddress(roadType: 'Calle', mainRoad: '10A Bis'),
        SuggestedAddress(roadType: 'Calle', mainRoad: '10A Bis', crossRoad: '67A'),
      ]);
    });

    test('when the address has no line it asks for the street first', () async {
      final geocoding = FakeGeocodingRepository(
        place: const GeocodedPlace(road: 'Calle 10A Bis'),
        streetAnswers: const [GeocodedPlace(road: 'Calle 10A Bis', roadPath: calleLine), GeocodedPlace(road: 'Carrera 67A')],
      );

      final suggestion = await SuggestAddressUseCase(geocoding)(point).last;

      expect(geocoding.streetQueries.first, same(point));
      expect(suggestion.crossRoad, '67A');
    });

    test('with a plate it does not probe', () async {
      final geocoding = FakeGeocodingRepository(place: const GeocodedPlace(road: 'Calle 12', houseNumber: '5-37'));

      final suggestion = await SuggestAddressUseCase(geocoding)(point).last;

      expect(geocoding.streetQueries, isEmpty);
      expect(suggestion.crossRoad, '5');
    });

    test('if no probe finds a crossing street, the cross street stays empty', () async {
      final geocoding = FakeGeocodingRepository(
        place: const GeocodedPlace(road: 'Calle 10A Bis', roadPath: calleLine),
        streetAnswers: const [GeocodedPlace(road: 'Calle 10A Bis'), GeocodedPlace(road: 'Calle 10A')],
      );

      final suggestion = await SuggestAddressUseCase(geocoding)(point).last;

      expect(suggestion.crossRoad, isNull);
      expect(suggestion.mainRoad, '10A Bis');
    });

    test('if the street lookup fails, the rest of the suggestion is kept', () async {
      final geocoding = FakeGeocodingRepository(place: const GeocodedPlace(road: 'Calle 10A Bis', neighborhood: 'Limonar'))
        ..streetError = Exception('La sugerencia de dirección tardó demasiado.');

      final suggestion = await SuggestAddressUseCase(geocoding)(point).last;

      expect(suggestion, const SuggestedAddress(roadType: 'Calle', mainRoad: '10A Bis', neighborhood: 'Limonar'));
    });
  });

  test('asks the repository for the point and parses its answer', () async {
    final geocoding = FakeGeocodingRepository(place: const GeocodedPlace(road: 'Carrera 44', neighborhood: 'Tequendama'));

    final suggestion = await SuggestAddressUseCase(geocoding)(const Coordinates(latitude: 3.41, longitude: -76.54)).last;

    expect(geocoding.calls, 1);
    expect(suggestion, const SuggestedAddress(roadType: 'Carrera', mainRoad: '44', neighborhood: 'Tequendama'));
  });
}

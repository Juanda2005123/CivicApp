import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/usecases/detect_nearest_city_usecase.dart';

import '../../support/fakes.dart';

const _cali = City(
  id: 1,
  name: 'Cali',
  department: 'Valle del Cauca',
  latitude: 3.4516,
  longitude: -76.5320,
  isCapital: true,
  kind: CityKind.capital,
  radiusKm: 18.0,
);
const _jamundi = City(
  id: 2,
  name: 'Jamundí',
  department: 'Valle del Cauca',
  latitude: 3.2606,
  longitude: -76.5414,
  isCapital: false,
  kind: CityKind.satellite,
  radiusKm: 3.0,
);
const _pasto = City(
  id: 3,
  name: 'Pasto',
  department: 'Nariño',
  latitude: 1.2136,
  longitude: -77.2811,
  isCapital: true,
);

void main() {
  const cities = [_cali, _jamundi, _pasto];

  test('a point in southern Cali, closer to the Jamundí centre, still resolves to Cali', () {
    final city = DetectNearestCityUseCase.resolve(
      const Coordinates(latitude: 3.3398, longitude: -76.5332),
      cities,
    );
    expect(city, _cali);
  });

  test('inside the strict satellite radius resolves to the satellite', () {
    final city = DetectNearestCityUseCase.resolve(
      const Coordinates(latitude: 3.2606, longitude: -76.5414),
      cities,
    );
    expect(city, _jamundi);
  });

  test('outside any radius falls back to the nearest city', () {
    final city = DetectNearestCityUseCase.resolve(
      const Coordinates(latitude: 1.30, longitude: -77.30),
      cities,
    );
    expect(city, _pasto);
  });

  test('reads the position and the catalog through the repositories', () async {
    final useCase = DetectNearestCityUseCase(
      FakeLocationRepository(
        coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
      ),
      FakeCityRepository(cities),
    );
    expect(await useCase(), _cali);
  });

  test('propagates location errors with their message', () async {
    final useCase = DetectNearestCityUseCase(
      FakeLocationRepository(error: Exception('Location services are disabled')),
      FakeCityRepository(cities),
    );
    await expectLater(
      useCase(),
      throwsA(predicate((e) => e.toString().contains('Location services are disabled'))),
    );
  });
}

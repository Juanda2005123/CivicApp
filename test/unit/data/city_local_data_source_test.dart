import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/data/datasources/city_local_data_source.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/usecases/detect_nearest_city_usecase.dart';

void main() {
  final cities = CityLocalDataSource().getCities();

  String resolve(double lat, double lng) {
    return DetectNearestCityUseCase.resolve(
      Coordinates(latitude: lat, longitude: lng),
      cities,
    ).name;
  }

  group('local DANE catalog', () {
    test('contains the 51 official municipalities with unique ids', () {
      expect(cities, hasLength(51));
      expect(cities.map((c) => c.id).toSet(), hasLength(51));
    });
  });

  group('calibrated radii over the real catalog', () {
    test('south Cali (Bochalema, universities) resolves to Cali, not Jamundí', () {
      expect(resolve(3.3398, -76.5332), 'Cali');
    });

    test('Jamundí downtown resolves to Jamundí', () {
      expect(resolve(3.2606, -76.5414), 'Jamundí');
    });

    test('Soacha downtown resolves to Soacha', () {
      expect(resolve(4.5804, -74.2169), 'Soacha');
    });

    test('Bosa / Venecia, outside the Soacha core, resolves to Bogotá', () {
      expect(resolve(4.6000, -74.1500), 'Bogotá');
    });

    test('Itagüí downtown resolves to Itagüí', () {
      expect(resolve(6.1846, -75.5991), 'Itagüí');
    });

    test('Medellín centre resolves to Medellín', () {
      expect(resolve(6.2442, -75.5812), 'Medellín');
    });
  });
}

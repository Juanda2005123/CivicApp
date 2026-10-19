import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/repositories/city_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_cities_usecase.dart';

class _MockCityRepository implements CityRepository {
  final List<City> mockCities;

  _MockCityRepository(this.mockCities);

  @override
  Future<List<City>> getCities() async => mockCities;
}

void main() {
  group('GetCitiesUseCase Unit Tests', () {
    test('successfully retrieves list of coverage cities from repository', () async {
      final sampleCities = [
        const City(
          id: 1,
          nombre: 'Cali',
          departamento: 'Valle del Cauca',
          latitud: 3.4516,
          longitud: -76.5320,
          esCapital: true,
        ),
        const City(
          id: 2,
          nombre: 'Bogotá',
          departamento: 'Bogotá D.C.',
          latitud: 4.7110,
          longitud: -74.0721,
          esCapital: true,
        ),
      ];

      final repository = _MockCityRepository(sampleCities);
      final useCase = GetCitiesUseCase(repository);

      final result = await useCase();

      expect(result.length, 2);
      expect(result.first.name, 'Cali');
      expect(result.first.department, 'Valle del Cauca');
      expect(result.last.name, 'Bogotá');
    });
  });
}

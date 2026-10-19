import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/dane_cities.dart';
import 'package:vigia_app/features/auth/data/datasources/city_remote_data_source.dart';
import 'package:vigia_app/features/auth/data/repositories/city_repository_impl.dart';

class _FakeCityRemoteDataSource extends CityRemoteDataSource {
  _FakeCityRemoteDataSource() : super(supabaseClient: null);

  @override
  Future<List<DaneCity>> getCities() async {
    return [
      const DaneCity(
        id: 1,
        nombre: 'Cali',
        departamento: 'Valle del Cauca',
        latitud: 3.4516,
        longitud: -76.5320,
        esCapital: true,
      ),
    ];
  }
}

void main() {
  group('CityRepositoryImpl Unit Tests', () {
    test('delegates retrieval of cities to CityRemoteDataSource', () async {
      final fakeDataSource = _FakeCityRemoteDataSource();
      final repository = CityRepositoryImpl(remoteDataSource: fakeDataSource);

      final result = await repository.getCities();

      expect(result.length, 1);
      expect(result.first.id, 1);
      expect(result.first.nombre, 'Cali');
    });
  });
}

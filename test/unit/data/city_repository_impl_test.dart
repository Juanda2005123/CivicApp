import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/data/datasources/city_local_data_source.dart';
import 'package:vigia_app/features/auth/data/datasources/city_remote_data_source.dart';
import 'package:vigia_app/features/auth/data/repositories/city_repository_impl.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';

class _FakeRemote implements CityRemoteDataSource {
  final List<City>? cities;
  final Exception? error;
  _FakeRemote({this.cities, this.error});

  @override
  Future<List<City>> getCities() async {
    if (error != null) throw error!;
    return cities!;
  }
}

void main() {
  final local = CityLocalDataSource();

  test('uses the remote catalog and adds the conurbation calibration', () async {
    const remote = City(
      id: 99,
      name: 'Jamundí',
      department: 'Valle del Cauca',
      latitude: 3.2606,
      longitude: -76.5414,
      isCapital: false,
    );
    final repository = CityRepositoryImpl(_FakeRemote(cities: [remote]), local);

    final cities = await repository.getCities();

    expect(cities, hasLength(1));
    expect(cities.single.id, 99);
    expect(cities.single.kind, CityKind.satellite);
    expect(cities.single.radiusKm, 3.0);
  });

  test('keeps a remote city that has no calibration as independent', () async {
    const remote = City(
      id: 7,
      name: 'Nowhere',
      department: 'Nowhere',
      latitude: 0,
      longitude: 0,
      isCapital: false,
    );
    final repository = CityRepositoryImpl(_FakeRemote(cities: [remote]), local);

    expect((await repository.getCities()).single.kind, CityKind.independent);
  });

  test('falls back to the local catalog when the remote read fails', () async {
    final repository = CityRepositoryImpl(
      _FakeRemote(error: Exception('permission denied')),
      local,
    );

    expect(await repository.getCities(), hasLength(51));
  });

  test('falls back to the local catalog when the remote table is empty', () async {
    final repository = CityRepositoryImpl(_FakeRemote(cities: const []), local);

    expect(await repository.getCities(), hasLength(51));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/city_identity/domain/entities/city_identity.dart';
import 'package:vigia_app/features/city_identity/domain/entities/city_ref.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/get_city_identity_usecase.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/get_featured_cities_usecase.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/get_last_city_usecase.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/save_last_city_usecase.dart';

import '../../../support/fake_city_identity_repository.dart';

void main() {
  final cali = samplePack('cali', name: 'Cali', department: 'Valle del Cauca');
  final caribe = samplePack(
    'region-caribe',
    level: CityIdentityLevel.regional,
    slogan: '{ciudad} se cuida entre vecinos.',
  );

  late FakeCityIdentityRepository repository;

  setUp(() {
    repository = FakeCityIdentityRepository(
      fullPacks: [cali],
      regionalByDepartment: {'Atlántico': caribe},
    );
  });

  group('GetCityIdentityUseCase', () {
    test('a city with its own pack gets it', () {
      expect(GetCityIdentityUseCase(repository)('Cali', department: 'Valle del Cauca'), cali);
    });

    test('without a department only the name counts', () {
      expect(GetCityIdentityUseCase(repository)(' Cali '), cali);
    });

    test('a city without a pack gets the one of its region, with its own name in the words', () {
      final identity = GetCityIdentityUseCase(repository)('Barranquilla', department: 'Atlántico');

      expect(identity.level, CityIdentityLevel.regional);
      expect(identity.slug, 'region-caribe');
      expect(identity.name, 'Barranquilla');
      expect(identity.copy.slogan, 'Barranquilla se cuida entre vecinos.');
    });

    test('without a pack of its own or of its region it falls back to the default look', () {
      final identity = GetCityIdentityUseCase(repository)('Pasto', department: 'Nariño');

      expect(identity.level, CityIdentityLevel.fallback);
      expect(identity.name, 'Pasto');
      expect(identity.department, 'Nariño');
    });

    test('no city at all is the default look, never an error', () {
      expect(GetCityIdentityUseCase(repository)('  ').level, CityIdentityLevel.fallback);
    });
  });

  test('GetFeaturedCitiesUseCase lists the cities with their own pack', () {
    expect(GetFeaturedCitiesUseCase(repository)(), [cali]);
  });

  group('last city', () {
    test('reads what was saved', () async {
      await SaveLastCityUseCase(repository)(const CityRef(name: 'Cali', department: 'Valle del Cauca'));

      expect(await GetLastCityUseCase(repository)(), const CityRef(name: 'Cali', department: 'Valle del Cauca'));
    });

    test('an empty name is not saved', () async {
      await SaveLastCityUseCase(repository)(const CityRef(name: ' '));

      expect(repository.saved, isEmpty);
    });

    test('a failure reading or saving is ignored', () async {
      repository
        ..readError = Exception('sin acceso')
        ..saveError = Exception('sin acceso');

      expect(await GetLastCityUseCase(repository)(), isNull);
      await SaveLastCityUseCase(repository)(const CityRef(name: 'Cali'));
    });
  });
}

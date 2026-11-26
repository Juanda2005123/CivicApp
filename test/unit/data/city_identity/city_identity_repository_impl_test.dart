import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigia_app/features/auth/data/datasources/city_local_data_source.dart';
import 'package:vigia_app/features/city_identity/data/datasources/city_pack_local_data_source.dart';
import 'package:vigia_app/features/city_identity/data/datasources/last_city_local_data_source.dart';
import 'package:vigia_app/features/city_identity/data/datasources/packs/regional_packs.dart';
import 'package:vigia_app/features/city_identity/data/repositories/city_identity_repository_impl.dart';
import 'package:vigia_app/features/city_identity/domain/entities/city_identity.dart';
import 'package:vigia_app/features/city_identity/domain/entities/city_ref.dart';
import 'package:vigia_app/features/city_identity/domain/entities/day_part.dart';
import 'package:vigia_app/features/city_identity/domain/usecases/get_city_identity_usecase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CityIdentityRepositoryImpl repository;
  late GetCityIdentityUseCase getIdentity;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = CityIdentityRepositoryImpl(CityPackLocalDataSource(), LastCityLocalDataSource());
    getIdentity = GetCityIdentityUseCase(repository);
  });

  test('Cali and Medellín have their own pack, with or without accents and capitals', () {
    expect(getIdentity('Cali', department: 'Valle del Cauca').slug, 'cali');
    expect(getIdentity('MEDELLIN', department: 'antioquia').slug, 'medellin');
    expect(getIdentity('Medellín').slug, 'medellin');
  });

  test('a city of the same name in another department does not borrow the pack', () {
    expect(getIdentity('Cali', department: 'Nariño').level, CityIdentityLevel.fallback);
  });

  test('while the regions have no design, the other cities look like the default pack', () {
    final packed = {for (final pack in repository.getFullPacks()) pack.name};

    for (final city in CityLocalDataSource().getCities()) {
      final identity = getIdentity(city.name, department: city.department);
      final hasPack = packed.contains(city.name);

      expect(identity.level, hasPack ? CityIdentityLevel.full : CityIdentityLevel.fallback, reason: city.name);
      expect(identity.name, city.name);
    }
  });

  test('every full pack is a city of the coverage catalog, with the same name and department', () {
    final catalog = CityLocalDataSource().getCities();

    for (final pack in repository.getFullPacks()) {
      expect(
        catalog.any((city) => city.name == pack.name && city.department == pack.department),
        isTrue,
        reason: '${pack.name} (${pack.department}) must match the DANE catalog (RN-12)',
      );
    }
  });

  test('every department of the catalog belongs to a region', () {
    for (final city in CityLocalDataSource().getCities()) {
      expect(regionOfDepartment(city.department), isNotNull, reason: city.department);
    }
    expect(regionOfDepartment('Atlántico'), ColombianRegion.caribe);
    expect(regionOfDepartment('Valle del Cauca'), ColombianRegion.pacifico);
    expect(regionOfDepartment('Bogotá D.C.'), ColombianRegion.andina);
    expect(regionOfDepartment('San Andrés y Providencia'), ColombianRegion.insular);
  });

  test('every full pack has the three header photos, the four places and their files', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    for (final pack in repository.getFullPacks()) {
      expect(pack.heroes.keys.toSet(), DayPart.values.toSet(), reason: pack.slug);
      expect(pack.landmarks.map((landmark) => landmark.rankName),
          ['Observador Urbano', 'Vecino Activo', 'Guardián Vial', 'Veedor Mayor'],
          reason: pack.slug);
      expect(pubspec, contains('assets/cities/${pack.slug}/'), reason: 'declare the folder in pubspec.yaml');

      final photos = [...pack.heroes.values, for (final landmark in pack.landmarks) landmark.photo!];
      for (final photo in photos) {
        final file = File(photo.assetPath);
        expect(file.existsSync(), isTrue, reason: photo.assetPath);
        expect(file.lengthSync(), lessThan(200 * 1000), reason: photo.assetPath);
        expect(photo.description, isNotEmpty, reason: photo.assetPath);
      }
    }
  });

  test('the last city survives a new launch', () async {
    expect(await repository.readLastCity(), isNull);

    await repository.saveLastCity(const CityRef(name: 'Medellín', department: 'Antioquia'));

    expect(await repository.readLastCity(), const CityRef(name: 'Medellín', department: 'Antioquia'));
  });
}

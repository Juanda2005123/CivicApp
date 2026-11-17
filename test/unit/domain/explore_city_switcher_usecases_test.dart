import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/explore/domain/usecases/get_city_options_usecase.dart';
import 'package:vigia_app/features/explore/domain/usecases/search_cities_usecase.dart';
import 'package:vigia_app/features/explore/domain/usecases/switch_city_usecase.dart';

import '../../support/fakes.dart';

City _city(int id, String name, String department) =>
    City(id: id, name: name, department: department, latitude: 0, longitude: 0, isCapital: true);

final _bogota = _city(1, 'Bogotá', 'Cundinamarca');
final _medellin = _city(2, 'Medellín', 'Antioquia');
final _cali = _city(3, 'Cali', 'Valle del Cauca');
final _pasto = _city(4, 'Pasto', 'Nariño');
final _narino = _city(5, 'San Andrés de Tumaco', 'Nariño');
final _all = [_bogota, _medellin, _cali, _pasto, _narino];

void main() {
  group('SearchCitiesUseCase', () {
    final search = SearchCitiesUseCase();

    test('ignores accents and case', () {
      expect(search(_all, 'bogota'), [_bogota]);
      expect(search(_all, 'MEDELLIN'), [_medellin]);
    });

    test('matches the department too', () {
      expect(search(_all, 'narino'), [_pasto, _narino]);
    });

    test('cities that start with the text come first', () {
      final santaMarta = _city(10, 'Santa Marta', 'Magdalena');
      final martaLucia = _city(11, 'Marta Lucía', 'Meta');

      expect(search([santaMarta, martaLucia], 'marta'), [martaLucia, santaMarta]);
    });

    test('an empty query finds nothing', () {
      expect(search(_all, '   '), isEmpty);
    });

    test('answers at most eight cities', () {
      final many = [for (var i = 0; i < 20; i++) _city(i, 'Villa $i', 'Meta')];

      expect(search(many, 'villa'), hasLength(SearchCitiesUseCase.maxResults));
    });
  });

  group('GetCityOptionsUseCase', () {
    test('returns the catalog, the recents in order and the quick cities', () async {
      final recents = FakeRecentCitiesRepository(['Pasto', 'Cali', 'Atlantis']);

      final options = await GetCityOptionsUseCase(FakeCityRepository(_all), recents)();

      expect(options.all, _all);
      expect(options.recent, [_pasto, _cali]);
      expect(options.quick, [_bogota, _medellin, _cali]);
    });
  });

  group('SwitchCityUseCase', () {
    late FakeAuthRepository auth;
    late FakeProfileRepository profiles;
    late FakeRecentCitiesRepository recents;

    setUp(() {
      auth = FakeAuthRepository(user: const AuthUser(id: 'uid-1', email: 'ana@example.com'));
      profiles = FakeProfileRepository()
        ..stored['uid-1'] = const Profile(
          id: 'uid-1',
          email: 'ana@example.com',
          fullName: 'Ana Gomez',
          cityName: 'Cali',
        );
      recents = FakeRecentCitiesRepository(['Cali', 'Pasto']);
    });

    test('a citizen saves last_city and the city goes first in the recents', () async {
      await SwitchCityUseCase(auth, profiles, recents)(_pasto);

      expect(profiles.stored['uid-1']!.lastCityName, 'Pasto');
      expect(profiles.stored['uid-1']!.cityName, 'Cali');
      expect(recents.names, ['Pasto', 'Cali']);
    });

    test('keeps only the three most recent cities', () async {
      recents.names = ['Cali', 'Pasto', 'Bogotá'];

      await SwitchCityUseCase(auth, profiles, recents)(_medellin);

      expect(recents.names, ['Medellín', 'Cali', 'Pasto']);
    });

    test('a guest has no profile to update: only the device remembers', () async {
      auth = FakeAuthRepository();

      await SwitchCityUseCase(auth, profiles, recents)(_pasto);

      expect(profiles.calls, isEmpty);
      expect(recents.names, ['Pasto', 'Cali']);
    });

    test('when saving last_city fails the recents stay as they were', () async {
      profiles.updateLastCityError = Exception('No pudimos guardar tu ciudad.');

      await expectLater(SwitchCityUseCase(auth, profiles, recents)(_pasto), throwsException);
      expect(recents.names, ['Cali', 'Pasto']);
    });
  });
}

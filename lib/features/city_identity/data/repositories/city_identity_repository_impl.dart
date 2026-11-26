import '../../domain/entities/city_identity.dart';
import '../../domain/entities/city_ref.dart';
import '../../domain/repositories/city_identity_repository.dart';
import '../datasources/city_pack_local_data_source.dart';
import '../datasources/last_city_local_data_source.dart';

class CityIdentityRepositoryImpl implements CityIdentityRepository {
  final CityPackLocalDataSource _packs;
  final LastCityLocalDataSource _lastCity;

  CityIdentityRepositoryImpl(this._packs, this._lastCity);

  @override
  CityIdentity? findFullPack(String cityName, {String? department}) =>
      _packs.findFullPack(cityName, department: department);

  @override
  CityIdentity? findRegionalPack(String department) => _packs.findRegionalPack(department);

  @override
  CityIdentity getDefaultPack() => _packs.getDefaultPack();

  @override
  List<CityIdentity> getFullPacks() => _packs.getFullPacks();

  @override
  Future<CityRef?> readLastCity() => _lastCity.read();

  @override
  Future<void> saveLastCity(CityRef city) => _lastCity.save(city);
}

import '../entities/city_identity.dart';
import '../repositories/city_identity_repository.dart';

/// The look of a city: its own pack, else the pack of its region, else the
/// default one. It never fails: a city without a design is still a city.
class GetCityIdentityUseCase {
  final CityIdentityRepository _repository;

  GetCityIdentityUseCase(this._repository);

  CityIdentity call(String cityName, {String? department}) {
    final name = cityName.trim();
    final region = department?.trim() ?? '';
    if (name.isEmpty) return _repository.getDefaultPack();

    final full = _repository.findFullPack(name, department: region.isEmpty ? null : region);
    if (full != null) return full;

    final regional = region.isEmpty ? null : _repository.findRegionalPack(region);
    return (regional ?? _repository.getDefaultPack()).forCity(name, region);
  }
}

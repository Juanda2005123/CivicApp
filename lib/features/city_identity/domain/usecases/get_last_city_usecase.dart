import '../entities/city_ref.dart';
import '../repositories/city_identity_repository.dart';

/// The city the app dressed for last time, so the splash and the login open
/// with it. A failure only means there is none.
class GetLastCityUseCase {
  final CityIdentityRepository _repository;

  GetLastCityUseCase(this._repository);

  Future<CityRef?> call() async {
    try {
      final city = await _repository.readLastCity();
      return (city == null || city.name.trim().isEmpty) ? null : city;
    } on Exception {
      return null;
    }
  }
}

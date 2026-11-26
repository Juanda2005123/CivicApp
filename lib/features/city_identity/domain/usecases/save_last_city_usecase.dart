import '../entities/city_ref.dart';
import '../repositories/city_identity_repository.dart';

/// Remembers the city the app is dressed for. Losing it only costs the next
/// launch its look, so a failure is ignored.
class SaveLastCityUseCase {
  final CityIdentityRepository _repository;

  SaveLastCityUseCase(this._repository);

  Future<void> call(CityRef city) async {
    if (city.name.trim().isEmpty) return;
    try {
      await _repository.saveLastCity(city);
    } on Exception {
      // The app keeps working without a remembered city.
    }
  }
}

import '../entities/city.dart';
import '../repositories/city_repository.dart';

/// Use case: official coverage cities for the citizen onboarding.
class GetCitiesUseCase {
  final CityRepository _cities;

  GetCitiesUseCase(this._cities);

  Future<List<City>> call() => _cities.getCities();
}

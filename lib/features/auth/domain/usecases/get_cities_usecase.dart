import '../entities/city.dart';
import '../repositories/city_repository.dart';

/// Use Case: Retrieve official coverage cities for citizen onboarding
class GetCitiesUseCase {
  final CityRepository repository;

  const GetCitiesUseCase(this.repository);

  Future<List<City>> call() {
    return repository.getCities();
  }
}

import '../entities/city_identity.dart';
import '../repositories/city_identity_repository.dart';

/// The cities with their own pack: the photo cards of the registration and the
/// thumbnails of the city switcher.
class GetFeaturedCitiesUseCase {
  final CityIdentityRepository _repository;

  GetFeaturedCitiesUseCase(this._repository);

  List<CityIdentity> call() => _repository.getFullPacks();
}

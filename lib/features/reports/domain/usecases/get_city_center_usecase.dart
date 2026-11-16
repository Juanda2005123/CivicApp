import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/repositories/city_repository.dart';

/// Use case: the center of a city of the official catalog (RN-12). It is where
/// a report starts when there is no GPS, and where the point stays when a typed
/// address cannot be located (HU-28).
class GetCityCenterUseCase {
  final CityRepository _cities;

  GetCityCenterUseCase(this._cities);

  Future<Coordinates> call(String cityName) async {
    final cities = await _cities.getCities();
    for (final city in cities) {
      if (city.name == cityName) return Coordinates(latitude: city.latitude, longitude: city.longitude);
    }
    throw Exception('No encontramos tu ciudad en el catálogo.');
  }
}

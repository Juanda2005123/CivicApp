import '../entities/city.dart';

/// Contract for the official coverage cities of VIGÍA.
abstract class CityRepository {
  Future<List<City>> getCities();
}

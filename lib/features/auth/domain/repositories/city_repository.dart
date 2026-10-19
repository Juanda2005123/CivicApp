import '../entities/city.dart';

/// Abstract contract for obtaining official civic coverage cities.
/// Decoupled from network, database or local cache mechanisms.
abstract class CityRepository {
  /// Retrieves the list of coverage cities supported by VIGÍA.
  Future<List<City>> getCities();
}

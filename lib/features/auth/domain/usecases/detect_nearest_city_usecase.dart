import 'dart:math';

import '../entities/city.dart';
import '../entities/coordinates.dart';
import '../repositories/city_repository.dart';
import '../repositories/location_repository.dart';

/// Use case: find the coverage city that corresponds to the device position.
///
/// Hierarchical calibrated-radii algorithm, so metropolitan conurbations are
/// resolved correctly (a point in southern Cali is closer to Jamundí's centre
/// than to Cali's, but still belongs to Cali):
/// 1. Inside the strict radius of a satellite municipality → that satellite.
/// 2. Else inside the absorption radius of a capital → that capital.
/// 3. Else the nearest city by great-circle distance.
class DetectNearestCityUseCase {
  final LocationRepository _location;
  final CityRepository _cities;

  DetectNearestCityUseCase(this._location, this._cities);

  Future<City> call() async {
    final position = await _location.currentCoordinates();
    final cities = await _cities.getCities();
    if (cities.isEmpty) throw Exception('No coverage cities available');
    return resolve(position, cities);
  }

  /// Pure resolution step, public so it can be tested without repositories.
  static City resolve(Coordinates position, List<City> cities) {
    final distances = {
      for (final city in cities) city: _distanceKm(position, city),
    };

    for (final kind in [CityKind.satellite, CityKind.capital]) {
      for (final city in cities) {
        final radius = city.radiusKm;
        if (city.kind == kind && radius != null && distances[city]! <= radius) {
          return city;
        }
      }
    }

    return cities.reduce((a, b) => distances[a]! <= distances[b]! ? a : b);
  }

  static double _distanceKm(Coordinates from, City to) {
    const earthRadiusKm = 6371.0;
    final dLat = _radians(to.latitude - from.latitude);
    final dLon = _radians(to.longitude - from.longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_radians(from.latitude)) *
            cos(_radians(to.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * pi / 180.0;
}

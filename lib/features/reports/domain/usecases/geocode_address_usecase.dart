import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/repositories/city_repository.dart';

import '../entities/location_source.dart';
import '../entities/resolved_location.dart';
import '../repositories/geocoding_repository.dart';
import '../validators/address_normalizer.dart';
import '../validators/report_validators.dart';

/// Use case: the point of the address a citizen typed in Step 1 (HU-28).
///
/// The address is rewritten the way the service reads it
/// ([AddressNormalizer]) and searched from the most to the least precise
/// query. A point is accepted only if it is inside Colombia (RN-12) and near
/// the city: Nominatim also knows a "Carrera 9" in every other city. When
/// nothing is found, or the service fails, the center of the city stands in,
/// so the citizen is never blocked (criterion 3) and can fix the point on the
/// map.
class GeocodeAddressUseCase {
  final GeocodingRepository _geocoding;
  final CityRepository _cities;

  GeocodeAddressUseCase(this._geocoding, this._cities);

  /// A match farther than this from the city center belongs to another place.
  static const double maxDistanceFromCityMeters = 25000;

  Future<ResolvedLocation> call({
    required String address,
    required String neighborhood,
    required String city,
  }) async {
    ReportValidators.validateAddress(address);

    final center = await _centerOf(city);
    final queries = AddressNormalizer.queries(address: address, neighborhood: neighborhood, city: city);
    for (final query in queries) {
      try {
        final point = await _geocoding.geocodeAddress(query);
        ReportValidators.validateCoordinates(point);
        if (point.distanceInMetersTo(center) <= maxDistanceFromCityMeters) {
          return ResolvedLocation(coordinates: point, source: LocationSource.address);
        }
      } on Exception {
        // This query found nothing usable (or the service failed): try the next.
      }
    }
    return ResolvedLocation(coordinates: center, source: LocationSource.cityCenter);
  }

  /// The center of [city] from the official catalog (RN-12).
  Future<Coordinates> _centerOf(String city) async {
    final cities = await _cities.getCities();
    for (final candidate in cities) {
      if (candidate.name == city) return Coordinates(latitude: candidate.latitude, longitude: candidate.longitude);
    }
    throw Exception('No encontramos tu ciudad en el catálogo.');
  }
}

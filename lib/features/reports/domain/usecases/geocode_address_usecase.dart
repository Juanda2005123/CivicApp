import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

import '../entities/address_outcome.dart';
import '../entities/resolved_location.dart';
import '../repositories/geocoding_repository.dart';
import '../validators/address_normalizer.dart';
import '../validators/report_validators.dart';
import 'get_city_center_usecase.dart';

/// Use case: the point of the address a citizen typed in Step 1 (HU-28).
///
/// The address is rewritten the way the service reads it
/// ([AddressNormalizer]) and searched from the most to the least precise
/// query. A point is accepted only if it is inside Colombia (RN-12) and near
/// the city: Nominatim also knows a "Carrera 9" in every other city. When
/// nothing is found, or the service fails, the center of the city stands in,
/// so the citizen is never blocked (criterion 3) and can fix the point on the
/// map. The [AddressOutcome] says which of those happened, so the wizard can
/// explain it.
class GeocodeAddressUseCase {
  final GeocodingRepository _geocoding;
  final GetCityCenterUseCase _getCityCenter;

  GeocodeAddressUseCase(this._geocoding, this._getCityCenter);

  /// A match farther than this from the city center belongs to another place.
  static const double maxDistanceFromCityMeters = 25000;

  Future<ResolvedLocation> call({
    required String address,
    required String neighborhood,
    required String city,
  }) async {
    ReportValidators.validateAddress(address);

    final center = await _getCityCenter(city);
    final queries = AddressNormalizer.queries(address: address, neighborhood: neighborhood, city: city);

    var serviceFailed = false;
    for (final query in queries) {
      try {
        final match = await _geocoding.geocodeAddress(query);
        if (match == null || !_isUsable(match.coordinates, center)) continue;
        return ResolvedLocation(
          coordinates: match.coordinates,
          outcome: match.isStreetOnly ? AddressOutcome.street : AddressOutcome.building,
        );
      } on Exception {
        // The service is slow or down: the next query would most likely fail
        // the same way, and each one waits for its timeout. Stop here.
        serviceFailed = true;
        break;
      }
    }

    return ResolvedLocation(coordinates: center, outcome: _whyNotFound(address, serviceFailed));
  }

  AddressOutcome _whyNotFound(String address, bool serviceFailed) {
    if (serviceFailed) return AddressOutcome.serviceFailed;
    final isUnderstood = AddressNormalizer.parse(address) != null;
    return AddressNormalizer.looksLikeAddress(address) && !isUnderstood
        ? AddressOutcome.notUnderstood
        : AddressOutcome.notFound;
  }

  /// Inside Colombia (RN-12) and near the city.
  bool _isUsable(Coordinates point, Coordinates center) {
    try {
      ReportValidators.validateCoordinates(point);
    } on Exception {
      return false;
    }
    return point.distanceInMetersTo(center) <= maxDistanceFromCityMeters;
  }
}

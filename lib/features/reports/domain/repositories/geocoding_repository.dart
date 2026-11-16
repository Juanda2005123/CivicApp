import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

import '../entities/address_match.dart';
import '../entities/geocoded_place.dart';

/// Contract for turning coordinates into an address (HU-26) and an address into
/// coordinates (HU-28). Each method
/// throws an [Exception] when the service is slow, unavailable or knows
/// nothing about the point.
abstract class GeocodingRepository {
  /// Address of the point: street, neighborhood and, when mapped, the plate.
  Future<GeocodedPlace> reverseGeocode(Coordinates coordinates);

  /// The street nearest to the point, with its line ([GeocodedPlace.roadPath]).
  Future<GeocodedPlace> streetAt(Coordinates coordinates);

  /// The point of a typed address (HU-28), for a [query] already written the way
  /// the service reads it. Only a street, a building or a place counts: a whole
  /// city or area is not an address. Answers null when nothing matches, and
  /// throws an [Exception] when the service is slow or unavailable, so the two
  /// can be told apart.
  Future<AddressMatch?> geocodeAddress(String query);
}

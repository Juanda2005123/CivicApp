import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

import '../entities/geocoded_place.dart';

/// Contract for turning coordinates into an address (HU-26). Each method
/// throws an [Exception] when the service is slow, unavailable or knows
/// nothing about the point.
abstract class GeocodingRepository {
  /// Address of the point: street, neighborhood and, when mapped, the plate.
  Future<GeocodedPlace> reverseGeocode(Coordinates coordinates);

  /// The street nearest to the point, with its line ([GeocodedPlace.roadPath]).
  Future<GeocodedPlace> streetAt(Coordinates coordinates);
}

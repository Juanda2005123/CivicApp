import 'dart:math';

/// A geographic point. The domain's own type, so no location SDK leaks in.
class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates({required this.latitude, required this.longitude});

  static const double _earthRadiusMeters = 6371000;

  /// Great-circle (haversine) distance to [other], in meters.
  double distanceInMetersTo(Coordinates other) {
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    final a = pow(sin(dLat / 2), 2) +
        cos(_toRadians(latitude)) * cos(_toRadians(other.latitude)) * pow(sin(dLon / 2), 2);
    return 2 * _earthRadiusMeters * asin(sqrt(a));
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}

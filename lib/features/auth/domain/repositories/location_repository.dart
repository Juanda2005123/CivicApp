import '../entities/coordinates.dart';

/// Contract for reading the device position.
abstract class LocationRepository {
  /// Throws an [Exception] with a user-facing message when the position
  /// cannot be obtained (service off, permission denied, timeout).
  Future<Coordinates> currentCoordinates();
}

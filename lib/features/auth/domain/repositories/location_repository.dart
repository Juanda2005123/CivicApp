import '../entities/coordinates.dart';

/// Contract for reading the device position.
abstract class LocationRepository {
  /// Message thrown by [currentCoordinates] when the user blocked the location
  /// permission. Blocs compare the whole message with this constant to offer
  /// the button that opens the system settings.
  static const blockedMessage =
      'El permiso de ubicación está bloqueado. Toca "Abrir ajustes" y luego Permisos → Ubicación.';

  /// Throws an [Exception] with a user-facing message when the position
  /// cannot be obtained (service off, permission denied or blocked, timeout).
  Future<Coordinates> currentCoordinates();

  /// Opens the app's system settings so the user can allow location again.
  /// Returns `false` when the platform cannot open them (e.g. the web).
  Future<bool> openSettings();
}

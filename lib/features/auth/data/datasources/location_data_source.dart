import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/coordinates.dart';

/// The only class that uses the location SDK. It translates its types into the
/// domain's [Coordinates] and its failures into user-facing messages.
class LocationDataSource {
  Future<Coordinates> currentCoordinates() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(
          'Location services are disabled. You can select your city from the list.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
            'Permission denied. Please select your city manually from the catalog.',
          );
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission permanently denied. Please use the city selector.');
      }

      final position = await _lastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 4),
            ),
          );
      return Coordinates(latitude: position.latitude, longitude: position.longitude);
    } on LocationServiceDisabledException {
      throw Exception(
        'Location services are disabled. You can select your city from the list.',
      );
    } on TimeoutException {
      throw Exception(_unavailable);
    } on Exception {
      // Our own messages above are already clear; anything else the SDK throws as
      // an Exception is rethrown untouched.
      rethrow;
    } catch (_) {
      // The SDK can throw Errors (not Exceptions) on some platforms; the Bloc
      // only handles Exceptions, so translate them here.
      throw Exception(_unavailable);
    }
  }

  static const _unavailable =
      'Unable to acquire GPS coordinates. Please select your city from the list.';

  /// `getLastKnownPosition` is not supported on the web (it throws an
  /// UnsupportedError); there the current position is requested instead.
  Future<Position?> _lastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } on UnsupportedError {
      return null;
    }
  }
}

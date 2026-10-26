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

      final position = await Geolocator.getLastKnownPosition() ??
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
      throw Exception('Unable to acquire GPS coordinates. Please select your city from the list.');
    }
  }
}

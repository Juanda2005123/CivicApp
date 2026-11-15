import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';

/// Interactor for reading the real-time physical device position.
class GetCurrentLocationUseCase {
  final LocationRepository _locationRepository;

  GetCurrentLocationUseCase(this._locationRepository);

  /// Returns current [Coordinates] from device sensors.
  Future<Coordinates> call() {
    return _locationRepository.currentCoordinates();
  }
}

import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';

/// Interactor for reading the real-time physical device position.
class GetCurrentLocationUseCase {
  final LocationRepository _locationRepository;

  GetCurrentLocationUseCase(this._locationRepository);

  /// Returns current [Coordinates] from device sensors. With [askPermission]
  /// false it never opens the system permission dialog.
  Future<Coordinates> call({bool askPermission = true}) {
    return _locationRepository.currentCoordinates(askPermission: askPermission);
  }
}

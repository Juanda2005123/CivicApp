import '../entities/device_permissions.dart';
import '../repositories/device_permissions_repository.dart';

/// Reads the current camera and location permissions (HU-02).
class GetDevicePermissionsUseCase {
  final DevicePermissionsRepository _repository;

  GetDevicePermissionsUseCase(this._repository);

  Future<DevicePermissionsSnapshot> call() => _repository.getStatus();
}

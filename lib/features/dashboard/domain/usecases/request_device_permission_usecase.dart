import '../entities/device_permissions.dart';
import '../repositories/device_permissions_repository.dart';

/// Requests a permission natively if never asked before, or opens OS settings
/// when it was already answered (HU-02, criteria 2–3).
class RequestDevicePermissionUseCase {
  final DevicePermissionsRepository _repository;

  RequestDevicePermissionUseCase(this._repository);

  Future<void> call({
    required DevicePermissionKind kind,
    required DevicePermissionState currentState,
  }) async {
    if (currentState == DevicePermissionState.notDetermined) {
      if (kind == DevicePermissionKind.camera) {
        await _repository.requestCamera();
      } else {
        await _repository.requestLocation();
      }
      return;
    }
    await _repository.openAppSettings();
  }
}

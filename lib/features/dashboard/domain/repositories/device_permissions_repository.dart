import '../entities/device_permissions.dart';

/// Contract for reading and requesting camera and location permissions (HU-02).
abstract class DevicePermissionsRepository {
  Future<DevicePermissionsSnapshot> getStatus();

  Future<DevicePermissionState> requestCamera();

  Future<DevicePermissionState> requestLocation();

  Future<bool> openAppSettings();
}

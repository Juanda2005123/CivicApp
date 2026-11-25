import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/entities/device_permissions.dart';

/// The only class that talks to `permission_handler` (HU-02).
class DevicePermissionsDataSource {
  Future<DevicePermissionsSnapshot> getStatus() async {
    final camera = await ph.Permission.camera.status;
    final location = await ph.Permission.locationWhenInUse.status;
    return DevicePermissionsSnapshot(
      camera: _map(camera),
      location: _map(location),
    );
  }

  Future<DevicePermissionState> requestCamera() async {
    final status = await ph.Permission.camera.request();
    return _mapAfterRequest(status);
  }

  Future<DevicePermissionState> requestLocation() async {
    final status = await ph.Permission.locationWhenInUse.request();
    return _mapAfterRequest(status);
  }

  Future<bool> openAppSettings() => ph.openAppSettings();

  DevicePermissionState _map(ph.PermissionStatus status) {
    if (status.isGranted || status.isLimited) return DevicePermissionState.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return DevicePermissionState.permanentlyDenied;
    }
    return DevicePermissionState.notDetermined;
  }

  DevicePermissionState _mapAfterRequest(ph.PermissionStatus status) {
    if (status.isGranted || status.isLimited) return DevicePermissionState.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return DevicePermissionState.permanentlyDenied;
    }
    return DevicePermissionState.denied;
  }
}

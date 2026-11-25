import 'package:equatable/equatable.dart';

/// Plain-domain status of a device permission (HU-02).
enum DevicePermissionState { notDetermined, granted, denied, permanentlyDenied }

enum DevicePermissionKind { camera, location }

/// Current camera and location permissions snapshot.
class DevicePermissionsSnapshot extends Equatable {
  final DevicePermissionState camera;
  final DevicePermissionState location;

  const DevicePermissionsSnapshot({
    required this.camera,
    required this.location,
  });

  @override
  List<Object?> get props => [camera, location];
}

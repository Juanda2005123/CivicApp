import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/dashboard/domain/entities/device_permissions.dart';
import 'package:vigia_app/features/dashboard/domain/repositories/device_permissions_repository.dart';
import 'package:vigia_app/features/dashboard/domain/usecases/get_device_permissions_usecase.dart';
import 'package:vigia_app/features/dashboard/domain/usecases/request_device_permission_usecase.dart';

class _FakePermissionsRepo implements DevicePermissionsRepository {
  DevicePermissionsSnapshot snapshot = const DevicePermissionsSnapshot(
    camera: DevicePermissionState.notDetermined,
    location: DevicePermissionState.granted,
  );
  bool requestedCamera = false;
  bool requestedLocation = false;
  bool openedSettings = false;

  @override
  Future<DevicePermissionsSnapshot> getStatus() async => snapshot;

  @override
  Future<DevicePermissionState> requestCamera() async {
    requestedCamera = true;
    return DevicePermissionState.granted;
  }

  @override
  Future<DevicePermissionState> requestLocation() async {
    requestedLocation = true;
    return DevicePermissionState.granted;
  }

  @override
  Future<bool> openAppSettings() async {
    openedSettings = true;
    return true;
  }
}

void main() {
  late _FakePermissionsRepo repo;
  late GetDevicePermissionsUseCase getPermissions;
  late RequestDevicePermissionUseCase requestPermission;

  setUp(() {
    repo = _FakePermissionsRepo();
    getPermissions = GetDevicePermissionsUseCase(repo);
    requestPermission = RequestDevicePermissionUseCase(repo);
  });

  test('GetDevicePermissionsUseCase returns camera and location status', () async {
    final result = await getPermissions();
    expect(result.camera, DevicePermissionState.notDetermined);
    expect(result.location, DevicePermissionState.granted);
  });

  test('RequestDevicePermissionUseCase prompts OS when camera is notDetermined', () async {
    await requestPermission(
      kind: DevicePermissionKind.camera,
      currentState: DevicePermissionState.notDetermined,
    );
    expect(repo.requestedCamera, isTrue);
    expect(repo.openedSettings, isFalse);
  });

  test('RequestDevicePermissionUseCase opens OS settings when permission was already answered', () async {
    await requestPermission(
      kind: DevicePermissionKind.location,
      currentState: DevicePermissionState.denied,
    );
    expect(repo.openedSettings, isTrue);
    expect(repo.requestedLocation, isFalse);
  });
}

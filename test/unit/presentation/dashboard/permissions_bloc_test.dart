import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/dashboard/domain/entities/device_permissions.dart';
import 'package:vigia_app/features/dashboard/domain/repositories/device_permissions_repository.dart';
import 'package:vigia_app/features/dashboard/domain/usecases/get_device_permissions_usecase.dart';
import 'package:vigia_app/features/dashboard/domain/usecases/request_device_permission_usecase.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/permissions_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/permissions_event.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/permissions_state.dart';

class _FakePermissionsRepo implements DevicePermissionsRepository {
  DevicePermissionsSnapshot snapshot = const DevicePermissionsSnapshot(
    camera: DevicePermissionState.notDetermined,
    location: DevicePermissionState.denied,
  );
  bool openedSettings = false;

  @override
  Future<DevicePermissionsSnapshot> getStatus() async => snapshot;

  @override
  Future<DevicePermissionState> requestCamera() async {
    snapshot = DevicePermissionsSnapshot(
      camera: DevicePermissionState.granted,
      location: snapshot.location,
    );
    return DevicePermissionState.granted;
  }

  @override
  Future<DevicePermissionState> requestLocation() async => snapshot.location;

  @override
  Future<bool> openAppSettings() async {
    openedSettings = true;
    return true;
  }
}

void main() {
  late _FakePermissionsRepo repo;
  late PermissionsBloc bloc;

  setUp(() {
    repo = _FakePermissionsRepo();
    bloc = PermissionsBloc(
      GetDevicePermissionsUseCase(repo),
      RequestDevicePermissionUseCase(repo),
    );
  });

  tearDown(() => bloc.close());

  test('PermissionsStarted loads camera and location status', () async {
    bloc.add(PermissionsStarted());
    await expectLater(
      bloc.stream,
      emitsThrough(predicate<PermissionsState>(
        (s) =>
            s.status == PermissionsStatus.ready &&
            s.permissions?.camera == DevicePermissionState.notDetermined &&
            s.permissions?.location == DevicePermissionState.denied,
      )),
    );
  });

  test('CameraPermissionTapped updates camera state to granted', () async {
    bloc.add(PermissionsStarted());
    await Future<void>.delayed(Duration.zero);

    bloc.add(CameraPermissionTapped());
    await expectLater(
      bloc.stream,
      emitsThrough(predicate<PermissionsState>(
        (s) => s.permissions?.camera == DevicePermissionState.granted,
      )),
    );
  });

  test('LocationPermissionTapped opens OS settings when already answered', () async {
    bloc.add(PermissionsStarted());
    await Future<void>.delayed(Duration.zero);

    bloc.add(LocationPermissionTapped());
    await Future<void>.delayed(Duration.zero);
    expect(repo.openedSettings, isTrue);
  });
}

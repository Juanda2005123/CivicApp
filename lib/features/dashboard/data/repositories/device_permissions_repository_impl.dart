import '../../domain/entities/device_permissions.dart';
import '../../domain/repositories/device_permissions_repository.dart';
import '../datasources/device_permissions_data_source.dart';

class DevicePermissionsRepositoryImpl implements DevicePermissionsRepository {
  final DevicePermissionsDataSource _dataSource;

  DevicePermissionsRepositoryImpl(this._dataSource);

  @override
  Future<DevicePermissionsSnapshot> getStatus() => _dataSource.getStatus();

  @override
  Future<DevicePermissionState> requestCamera() => _dataSource.requestCamera();

  @override
  Future<DevicePermissionState> requestLocation() => _dataSource.requestLocation();

  @override
  Future<bool> openAppSettings() => _dataSource.openAppSettings();
}

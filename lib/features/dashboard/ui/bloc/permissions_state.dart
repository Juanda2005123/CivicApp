import '../../domain/entities/device_permissions.dart';

enum PermissionsStatus { initial, loading, ready, failure }

class PermissionsState {
  final PermissionsStatus status;
  final DevicePermissionsSnapshot? permissions;
  final String? errorMessage;

  const PermissionsState({
    this.status = PermissionsStatus.initial,
    this.permissions,
    this.errorMessage,
  });

  PermissionsState copyWith({
    PermissionsStatus? status,
    DevicePermissionsSnapshot? permissions,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PermissionsState(
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

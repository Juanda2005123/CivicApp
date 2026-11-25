import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/device_permissions.dart';
import '../../domain/usecases/get_device_permissions_usecase.dart';
import '../../domain/usecases/request_device_permission_usecase.dart';
import 'permissions_event.dart';
import 'permissions_state.dart';

/// Manages camera and location permissions status in "Permisos" (HU-02).
class PermissionsBloc extends Bloc<PermissionsEvent, PermissionsState> {
  final GetDevicePermissionsUseCase _getPermissions;
  final RequestDevicePermissionUseCase _requestPermission;

  PermissionsBloc(this._getPermissions, this._requestPermission) : super(const PermissionsState()) {
    on<PermissionsStarted>(_onLoad);
    on<PermissionsRefreshed>(_onLoad);
    on<CameraPermissionTapped>(
      (_, emit) => _onPermissionTapped(DevicePermissionKind.camera, emit),
    );
    on<LocationPermissionTapped>(
      (_, emit) => _onPermissionTapped(DevicePermissionKind.location, emit),
    );
  }

  Future<void> _onLoad(PermissionsEvent event, Emitter<PermissionsState> emit) async {
    if (state.permissions == null) {
      emit(state.copyWith(status: PermissionsStatus.loading, clearErrorMessage: true));
    }
    try {
      final snapshot = await _getPermissions();
      emit(state.copyWith(status: PermissionsStatus.ready, permissions: snapshot));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: PermissionsStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onPermissionTapped(
    DevicePermissionKind kind,
    Emitter<PermissionsState> emit,
  ) async {
    final current = state.permissions;
    if (current == null) return;
    final currentState =
        kind == DevicePermissionKind.camera ? current.camera : current.location;
    try {
      await _requestPermission(kind: kind, currentState: currentState);
      final updated = await _getPermissions();
      emit(state.copyWith(status: PermissionsStatus.ready, permissions: updated));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: PermissionsStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}

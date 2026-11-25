import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/theme/theme_cubit.dart';
import 'package:vigia_app/features/dashboard/domain/entities/device_permissions.dart';
import 'package:vigia_app/features/dashboard/domain/repositories/device_permissions_repository.dart';
import 'package:vigia_app/features/dashboard/domain/usecases/get_device_permissions_usecase.dart';
import 'package:vigia_app/features/dashboard/domain/usecases/request_device_permission_usecase.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/permissions_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/permissions_event.dart';
import 'package:vigia_app/features/dashboard/ui/screens/permissions_screen.dart';

class _FakePermissionsRepo implements DevicePermissionsRepository {
  @override
  Future<DevicePermissionsSnapshot> getStatus() async => const DevicePermissionsSnapshot(
        camera: DevicePermissionState.notDetermined,
        location: DevicePermissionState.granted,
      );

  @override
  Future<DevicePermissionState> requestCamera() async => DevicePermissionState.granted;

  @override
  Future<DevicePermissionState> requestLocation() async => DevicePermissionState.granted;

  @override
  Future<bool> openAppSettings() async => true;
}

void main() {
  testWidgets('PermissionsScreen displays camera and location with plain-text status', (tester) async {
    final repo = _FakePermissionsRepo();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(
            create: (_) => PermissionsBloc(
              GetDevicePermissionsUseCase(repo),
              RequestDevicePermissionUseCase(repo),
            )..add(PermissionsStarted()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const PermissionsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Permisos'), findsOneWidget);
    expect(find.text('Cámara'), findsOneWidget);
    expect(find.text('Ubicación'), findsOneWidget);
    expect(find.textContaining('No solicitado'), findsOneWidget);
    expect(find.textContaining('Permitido'), findsOneWidget);
  });
}

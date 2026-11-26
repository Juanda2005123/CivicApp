import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/city/city_motion.dart';
import '../../../../core/widgets/dotted_spinner.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../domain/entities/device_permissions.dart';
import '../bloc/permissions_bloc.dart';
import '../bloc/permissions_event.dart';
import '../bloc/permissions_state.dart';
import 'package:vigia_app/core/theme/city_theme.dart';

/// "Permisos" screen (HU-02): shows camera and location permissions in plain
/// text and refreshes automatically when returning from OS settings.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<PermissionsBloc>().add(PermissionsRefreshed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permisos'),
        actions: const [ThemeToggleButton()],
      ),
      body: BlocBuilder<PermissionsBloc, PermissionsState>(
        builder: (context, state) {
          final permissions = state.permissions;

          if (state.status == PermissionsStatus.loading && permissions == null) {
            return const Center(
              child: DottedSpinner(size: 36, semanticLabel: 'Cargando permisos'),
            );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Permisos del dispositivo', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Administra cómo VIGÍA accede a tu cámara y ubicación. Si deniegas alguno, aún puedes subir fotos de tu galería y ubicar el pin manualmente.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (state.status == PermissionsStatus.failure && state.errorMessage != null) ...[
                      AppNotice(kind: NoticeKind.error, message: state.errorMessage!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (permissions != null) ...[
                      _PermissionCard(
                        icon: LucideIcons.camera,
                        title: 'Cámara',
                        status: permissions.camera,
                        onTap: () =>
                            context.read<PermissionsBloc>().add(CameraPermissionTapped()),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PermissionCard(
                        icon: LucideIcons.mapPin,
                        title: 'Ubicación',
                        status: permissions.location,
                        onTap: () =>
                            context.read<PermissionsBloc>().add(LocationPermissionTapped()),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final DevicePermissionState status;
  final VoidCallback onTap;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _statusLabel(status);
    final hint = status == DevicePermissionState.notDetermined
        ? 'Toca para solicitar permiso'
        : 'Toca para abrir ajustes del dispositivo';

    return PressScale(
      child: Card(
        child: ListTile(
          minTileHeight: AppSizes.touchTarget,
          leading: Icon(icon, color: CityTheme.of(context).deep),
          title: Text(title, style: theme.textTheme.bodyLarge),
          subtitle: Text(
            '$label · $hint',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: const Icon(LucideIcons.chevronRight),
          onTap: onTap,
        ),
      ),
    );
  }

  String _statusLabel(DevicePermissionState status) {
    switch (status) {
      case DevicePermissionState.granted:
        return 'Permitido';
      case DevicePermissionState.notDetermined:
        return 'No solicitado';
      case DevicePermissionState.denied:
        return 'Denegado';
      case DevicePermissionState.permanentlyDenied:
        return 'Bloqueado';
    }
  }
}

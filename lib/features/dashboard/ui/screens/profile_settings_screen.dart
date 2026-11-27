import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../bloc/privacy_bloc.dart';
import '../bloc/privacy_event.dart';
import '../bloc/privacy_state.dart';

/// Configuration screen opened from "Mi perfil": houses civic privacy (HU-01)
/// and future account/device settings.
class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        actions: const [ThemeToggleButton()],
      ),
      body: BlocBuilder<PrivacyBloc, PrivacyState>(
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Privacidad', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    if (state.status == PrivacyStatus.failure && state.errorMessage != null) ...[
                      AppNotice(kind: NoticeKind.error, message: state.errorMessage!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Card(
                      child: SwitchListTile(
                        value: state.showRealName,
                        onChanged: state.status == PrivacyStatus.saving
                            ? null
                            : (value) => context.read<PrivacyBloc>().add(PrivacyToggled(value)),
                        title: Text('Mostrar mi nombre', style: theme.textTheme.bodyLarge),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            'Si lo desactivas, tus reportes y comentarios mostrarán "Ciudadano anónimo" conservando tu rango cívico.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
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

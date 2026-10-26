import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/dotted_spinner.dart';
import '../../../../core/widgets/rank_seal.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../auth/domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

/// Citizen profile summary (Sprint 1 landing screen) with secure logout.
/// It only draws the [ProfileState]; nothing arrives through route arguments.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ProfileStatus.signedOut) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mi perfil'),
            automaticallyImplyLeading: false,
            actions: [
              const ThemeToggleButton(),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<ProfileBloc>().add(SignOutRequested()),
              ),
            ],
          ),
          body: SafeArea(child: _buildBody(context, state)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state) {
    final profile = state.profile;

    if (state.status == ProfileStatus.failure && profile == null) {
      return _LoadError(
        message: state.errorMessage ?? 'No pudimos cargar tu perfil.',
        onRetry: () => context.read<ProfileBloc>().add(ProfileStarted()),
      );
    }

    if (profile == null) {
      return const Center(child: DottedSpinner(size: 40, semanticLabel: 'Cargando tu perfil'));
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IdentityCard(profile: profile),
              const SizedBox(height: AppSpacing.lg),
              _DetailsCard(profile: profile),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => context.read<ProfileBloc>().add(SignOutRequested()),
                icon: const Icon(Icons.logout, size: AppSizes.icon),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final Profile profile;

  const _IdentityCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl - 4),
        child: Row(
          children: [
            RankSeal(
              level: profile.rankId,
              size: 72,
              semanticLabel: 'Nivel ${profile.rankId}, ${profile.rankName}',
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22, height: 28 / 22),
                  ),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(profile.rankName, style: theme.textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: AppStatusChip(label: 'Sesión activa'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final Profile profile;

  const _DetailsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _InfoRow(
        icon: Icons.star_outline,
        label: 'Puntos de reputación',
        value: '${profile.experiencePoints} pts',
        mono: true,
      ),
      _InfoRow(icon: Icons.mail_outline, label: 'Correo electrónico', value: profile.email),
      _InfoRow(icon: Icons.location_on_outlined, label: 'Ciudad de residencia', value: profile.cityName),
      _InfoRow(
        icon: Icons.military_tech_outlined,
        label: 'Rango cívico',
        value: 'Nivel ${profile.rankId} · ${profile.rankName}',
      ),
    ];

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  const _InfoRow({required this.icon, required this.label, required this.value, this.mono = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: context.semantic.accent),
          const SizedBox(width: AppSpacing.md + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  value,
                  style: mono
                      ? AppTextStyles.data(size: 18, line: 24)
                      : theme.textTheme.bodyLarge?.copyWith(fontWeight: null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.lg),
            Text('No pudimos cargar tu perfil', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

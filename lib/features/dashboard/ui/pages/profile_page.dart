import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/civic_avatar.dart';
import '../../../../core/widgets/dotted_spinner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../reports/domain/entities/feed_incident.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/impact_counters.dart';
import '../widgets/my_reports_section.dart';
import '../widgets/rank_progress_card.dart';

/// "Mi perfil" tab of the shell: the citizen's civic impact dashboard (HU-23),
/// built on the profile summary of Sprint 1, with secure logout. A Page, so it
/// has no Scaffold; it only draws the [ProfileState]. A guest (HU-22) sees an
/// invitation to sign in instead.
class ProfilePage extends StatelessWidget {
  /// Opens the report wizard. The shell owns it because it also reloads the map and the feed.
  final VoidCallback onReportPressed;

  const ProfilePage({super.key, required this.onReportPressed});

  /// Room under the last item so the "Reportar daño" button of the shell does not
  /// cover "Cerrar sesión" when the dashboard is scrolled to the end.
  static const double bottomClearance = AppSpacing.xxxl + AppSizes.button + AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ProfileStatus.signedOut) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
        }
      },
      builder: (context, state) => _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state) {
    final profile = state.profile;

    if (state.status == ProfileStatus.guest) return const _GuestInvitation();

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
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.screen,
          AppSpacing.screen,
          AppSpacing.screen + bottomClearance,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IdentityCard(
                profile: profile,
                isUploadingAvatar: state.avatarStatus == AvatarUploadStatus.uploading,
                onAvatarTap: () => _pickAvatarSource(context),
              ),
              if (state.avatarStatus == AvatarUploadStatus.failure &&
                  state.avatarErrorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppNotice(kind: NoticeKind.error, message: state.avatarErrorMessage!),
              ],
              const SizedBox(height: AppSpacing.lg),
              _ImpactPanel(state: state),
              if (state.impactStatus == ImpactStatus.success) ...[
                const SizedBox(height: AppSpacing.xl),
                MyReportsSection(
                  reports: state.myReports,
                  onOpen: (report) => _openReport(context, report),
                  onReportFirst: onReportPressed,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _DetailsCard(profile: profile),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => _openSettings(context, profile),
                icon: const Icon(Icons.settings_outlined, size: AppSizes.icon),
                label: const Text('Configuración'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _openEditProfile(context, profile),
                icon: const Icon(Icons.edit_outlined, size: AppSizes.icon),
                label: const Text('Datos personales'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.permissions),
                icon: const Icon(Icons.security_outlined, size: AppSizes.icon),
                label: const Text('Permisos'),
              ),
              const SizedBox(height: AppSpacing.sm),
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

  /// Opens "Configuración" (HU-01) and refreshes the profile on return so any
  /// privacy or profile changes are reflected immediately.
  Future<void> _openSettings(BuildContext context, Profile profile) async {
    final bloc = context.read<ProfileBloc>();
    await Navigator.pushNamed(context, AppRoutes.profileSettings, arguments: profile);
    bloc.add(ProfileRefreshed());
  }

  /// Opens "Datos personales" (HU-04) and refreshes the profile on return.
  Future<void> _openEditProfile(BuildContext context, Profile profile) async {
    final bloc = context.read<ProfileBloc>();
    await Navigator.pushNamed(context, AppRoutes.editProfile, arguments: profile);
    bloc.add(ProfileRefreshed());
  }

  /// Opens a bottom sheet so the citizen can pick a new avatar from camera or gallery (HU-05).
  Future<void> _pickAvatarSource(BuildContext context) async {
    final bloc = context.read<ProfileBloc>();
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  bloc.add(ProfileAvatarChangeRequested(fromCamera: true));
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  bloc.add(ProfileAvatarChangeRequested(fromCamera: false));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// The detail opens on top of the shell. Back from it the numbers are read
  /// again: the citizen may have received or given an endorsement meanwhile.
  Future<void> _openReport(BuildContext context, FeedIncident report) async {
    final bloc = context.read<ProfileBloc>();
    await Navigator.pushNamed(context, AppRoutes.reportDetail, arguments: report.id);
    bloc.add(ProfileRefreshed());
  }
}

/// Progress to the next rank and the four counters (HU-23). While they load a
/// spinner holds the place; if they cannot load, the message and a retry show
/// and the rest of the profile stays usable.
class _ImpactPanel extends StatelessWidget {
  final ProfileState state;

  const _ImpactPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final impact = state.impact;
    final progress = state.rankProgress;

    if (impact != null && progress != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RankProgressCard(progress: progress),
          const SizedBox(height: AppSpacing.md),
          ImpactCounters(impact: impact),
        ],
      );
    }

    if (state.impactStatus == ImpactStatus.failure) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNotice(
            kind: NoticeKind.error,
            message: state.impactErrorMessage ?? 'No pudimos cargar tu impacto.',
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => context.read<ProfileBloc>().add(ProfileStarted()),
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Center(child: DottedSpinner(size: 32, semanticLabel: 'Cargando tu impacto')),
    );
  }
}

/// Replaces the civic dashboard for a guest (HU-22, criterion 4).
class _GuestInvitation extends StatelessWidget {
  const _GuestInvitation();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.person_outline, size: AppSpacing.xxxl, color: context.semantic.accent),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Inicia sesión para ver tu perfil',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Con una cuenta puedes reportar daños, apoyar reportes y ganar puntos de reputación.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Iniciar sesión',
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text('Crear cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final Profile profile;
  final bool isUploadingAvatar;
  final VoidCallback onAvatarTap;

  const _IdentityCard({
    required this.profile,
    required this.isUploadingAvatar,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl - 4),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Cambiar foto de perfil. Nivel ${profile.rankId}, ${profile.rankName}',
              child: InkWell(
                borderRadius: BorderRadius.circular(36),
                onTap: isUploadingAvatar ? null : onAvatarTap,
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CivicAvatar(
                        avatarUrl: profile.avatarUrl,
                        rankId: profile.rankId,
                        size: 72,
                      ),
                      if (isUploadingAvatar)
                        const DottedSpinner(size: 32, semanticLabel: 'Subiendo avatar'),
                    ],
                  ),
                ),
              ),
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
                  Text(
                    'Ciudadano',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
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

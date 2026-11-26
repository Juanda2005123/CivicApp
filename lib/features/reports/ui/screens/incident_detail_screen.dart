import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_colors.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_text_styles.dart';
import 'package:vigia_app/core/widgets/app_notice.dart';
import 'package:vigia_app/core/theme/city_theme.dart';
import 'package:vigia_app/core/theme/severity_colors.dart';
import 'package:vigia_app/core/widgets/city/celebration_overlay.dart';
import 'package:vigia_app/core/widgets/city/city_skeleton.dart';
import 'package:vigia_app/core/widgets/dotted_spinner.dart';
import 'package:vigia_app/core/widgets/severity_chip.dart';
import 'package:vigia_app/core/widgets/primary_button.dart';
import 'package:vigia_app/core/widgets/rank_seal.dart';
import 'package:vigia_app/core/widgets/sign_in_required_dialog.dart';
import 'package:vigia_app/core/widgets/validation_seal.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_photo.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/author_actions_card.dart';
import '../widgets/incident_comments_section.dart';
import '../bloc/incident_detail_bloc.dart';
import '../bloc/incident_detail_event.dart';
import '../bloc/incident_detail_state.dart';
import 'package:vigia_app/core/widgets/city/city_motion.dart';

/// Detailed inspection view for a public road damage report (HU-14).
class IncidentDetailScreen extends StatefulWidget {
  final String? incidentIdOrCode;

  const IncidentDetailScreen({
    super.key,
    this.incidentIdOrCode,
  });

  @override
  State<IncidentDetailScreen> createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  int _currentPhotoIndex = 0;
  String? _resolvedId;

  /// The author edited the report here: going back tells the caller to reload (HU-18).
  bool _changed = false;

  /// The report was already validated when the citizen tapped "Apoyar".
  bool _validatedBeforeTap = true;

  /// Keeps the thumb's animation when the button changes from filled to outlined.
  final _thumbKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedId == null) {
      final routeArg = ModalRoute.of(context)?.settings.arguments as String?;
      _resolvedId = widget.incidentIdOrCode ?? routeArg;
      if (_resolvedId != null && _resolvedId!.isNotEmpty) {
        context.read<IncidentDetailBloc>().add(IncidentDetailStarted(_resolvedId!));
      }
    }
  }

  void _retry() {
    if (_resolvedId != null && _resolvedId!.isNotEmpty) {
      context.read<IncidentDetailBloc>().add(IncidentDetailStarted(_resolvedId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope<Object?>(
      // After an edit, going back answers `true` so the map, the feed and the profile reload.
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(true);
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('Detalle del reporte', style: AppTextStyles.appBarTitle),
        centerTitle: false,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<IncidentDetailBloc, IncidentDetailState>(
            listenWhen: (previous, current) =>
                current.endorsementError != null && previous.endorsementError != current.endorsementError,
            listener: (context, state) => _showMessage(context, state.endorsementError!),
          ),
          // The optimistic copy does not touch the validation, so this is still how
          // the report was before the tap.
          BlocListener<IncidentDetailBloc, IncidentDetailState>(
            listenWhen: (previous, current) => !previous.isEndorsing && current.isEndorsing,
            listener: (context, state) => _validatedBeforeTap = state.incident?.isCommunityValidated ?? true,
          ),
          BlocListener<IncidentDetailBloc, IncidentDetailState>(
            listenWhen: (previous, current) => previous.isEndorsing && !current.isEndorsing,
            listener: _celebrateIfValidated,
          ),
          // The server may refuse a delete with the window over (HU-18, criterion 5).
          BlocListener<IncidentDetailBloc, IncidentDetailState>(
            listenWhen: (previous, current) =>
                current.deleteError != null && previous.deleteError != current.deleteError,
            listener: (context, state) => _showMessage(context, state.deleteError!),
          ),
          BlocListener<IncidentDetailBloc, IncidentDetailState>(
            listenWhen: (previous, current) => !previous.wasDeleted && current.wasDeleted,
            listener: (context, state) {
              _showMessage(context, 'Reporte eliminado.');
              Navigator.of(context).pop(true);
            },
          ),
        ],
        child: BlocBuilder<IncidentDetailBloc, IncidentDetailState>(
        builder: (context, state) {
          switch (state.status) {
            case IncidentDetailStatus.initial:
              if (_resolvedId == null || _resolvedId!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.screen),
                    child: AppNotice(
                      message: 'No se proporcionó un identificador de reporte válido.',
                      kind: NoticeKind.error,
                    ),
                  ),
                );
              }
              return const CitySkeleton(
                shape: CitySkeletonShape.detail,
                semanticLabel: 'Cargando reporte vial...',
              );

            // An empty case falls through in Dart: loading needs its own body,
            // or the screen shows the failure view until the report arrives.
            case IncidentDetailStatus.loading:
              return const CitySkeleton(
                shape: CitySkeletonShape.detail,
                semanticLabel: 'Cargando reporte vial...',
              );

            case IncidentDetailStatus.failure:
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppNotice(
                      message: state.errorMessage ?? 'No fue posible cargar el reporte vial.',
                      kind: NoticeKind.error,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Reintentar',
                      onPressed: _retry,
                    ),
                  ],
                ),
              );

            case IncidentDetailStatus.success:
              final incident = state.incident;
              if (incident == null) {
                return const Center(child: Text('Reporte no encontrado'));
              }
              return _buildIncidentDetail(context, state, incident, theme);
          }
        },
        ),
      ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 3A: the citizen's endorsement was the one that validated the report (HU-16).
  void _celebrateIfValidated(BuildContext context, IncidentDetailState state) {
    final incident = state.incident;
    if (incident == null || _validatedBeforeTap || !incident.isCommunityValidated) return;
    if (state.endorsementError != null) return;
    showValidationCelebration(context, reportCode: incident.trackingCode, endorsements: incident.upvotesCount);
  }

  /// Opens the edit form; coming back saved, the report is read again (HU-18).
  Future<void> _edit(Incident incident) async {
    final bloc = context.read<IncidentDetailBloc>();
    final saved = await Navigator.pushNamed(context, AppRoutes.reportEdit, arguments: incident);
    if (saved == true) {
      if (mounted) setState(() => _changed = true);
      bloc.add(const IncidentReloaded());
    }
  }

  Future<void> _confirmDelete() async {
    final bloc = context.read<IncidentDetailBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar este reporte?'),
        content: const Text(
          'Se quitarán el reporte y sus fotos del mapa y de la comunidad, y perderás los 100 XP que ganaste al publicarlo. '
          'No se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          PressScale(child: FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Eliminar'))),
        ],
      ),
    );
    if (confirmed == true) bloc.add(const IncidentDeleteRequested());
  }

  void _toggleEndorsement(BuildContext context, IncidentDetailState state) {
    if (state.isGuest) {
      showSignInRequiredDialog(
        context,
        message: 'Para apoyar un reporte necesitas una cuenta. Inicia sesión o regístrate; es gratis.',
        onSignIn: () => Navigator.pushNamed(context, AppRoutes.login),
        onRegister: () => Navigator.pushNamed(context, AppRoutes.register),
      );
      return;
    }
    context.read<IncidentDetailBloc>().add(const IncidentEndorsementToggled());
  }

  Widget _buildIncidentDetail(
    BuildContext context,
    IncidentDetailState state,
    Incident incident,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tracking Code, Status Chip, Severity Chip
          _buildHeaderSection(context, incident, theme),
          const SizedBox(height: AppSpacing.md),

          // Photo Gallery Carousel or Fallback
          _buildPhotoCarousel(context, incident.photos, theme),
          const SizedBox(height: AppSpacing.md),

          // Community Validation / Endorsement Progress Bar
          _buildEndorsementCard(context, incident, theme),
          // The author never endorses their own report (RN-05): no button for them.
          if (!state.viewerIsAuthor) ...[
            const SizedBox(height: AppSpacing.md),
            _buildEndorseButton(context, state, incident),
          ],
          // The author can edit or delete inside the window; afterwards the card says it is frozen (HU-18).
          if (state.viewerIsAuthor) ...[
            const SizedBox(height: AppSpacing.md),
            AuthorActionsCard(
              incident: incident,
              viewerId: state.viewerId!,
              isDeleting: state.isDeleting,
              onEdit: () => _edit(incident),
              onDelete: _confirmDelete,
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Problem Information Card
          _buildProblemCard(context, incident, theme),
          const SizedBox(height: AppSpacing.md),

          // Location and Coordinates Card
          _buildLocationCard(context, incident, theme),
          const SizedBox(height: AppSpacing.md),

          // Author Identity and Timestamp (Excluding email)
          _buildAuthorCard(context, incident, theme),
          const SizedBox(height: AppSpacing.xl),

          // Discussion thread and composer (HU-17)
          IncidentCommentsSection(incidentId: incident.id),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, Incident incident, ThemeData theme) {
    final semantic = context.semantic;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                incident.trackingCode,
                style: AppTextStyles.data(size: 20).copyWith(
                  fontWeight: FontWeight.bold,
                  color: CityTheme.of(context).deep,
                ),
              ),
              SeverityChip(level: _levelOf(incident.severity)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: semantic.infoContainer,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.info, size: 14, color: semantic.info),
                    const SizedBox(width: 4),
                    Text(
                      incident.status.labelSpanish,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: semantic.info,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (incident.categoryName != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '· ${incident.categoryName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// The theme has its own severity levels, so shared widgets never import the domain.
  SeverityLevel _levelOf(IncidentSeverity severity) => switch (severity) {
        IncidentSeverity.low => SeverityLevel.low,
        IncidentSeverity.medium => SeverityLevel.medium,
        IncidentSeverity.high => SeverityLevel.high,
        IncidentSeverity.critical => SeverityLevel.critical,
      };

  Widget _buildPhotoCarousel(BuildContext context, List<IncidentPhoto> photos, ThemeData theme) {
    if (photos.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.images, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sin fotografías adjuntas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _currentPhotoIndex = i),
            itemBuilder: (context, index) {
              final photo = photos[index];
              return Image.network(
                photo.fileUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.imageOff, size: 40),
                      const SizedBox(height: 4),
                      Text('Error cargando evidencia', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: DottedSpinner(size: 28));
                },
              );
            },
          ),
          // Photo counter pill (e.g. 1/3)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPhotoIndex + 1}/${photos.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndorsementCard(BuildContext context, Incident incident, ThemeData theme) {
    const target = Incident.validationTarget;
    final progress = (incident.upvotesCount / target).clamp(0.0, 1.0);
    final missing = incident.endorsementsMissing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The seal stays once earned, even if later revocations drop the count (HU-16).
        if (incident.isCommunityValidated) ...[
          ValidationSeal(endorsements: incident.upvotesCount),
          const SizedBox(height: AppSpacing.md),
        ],
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Validación comunitaria',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${incident.upvotesCount} de $target apoyos',
                    style: AppTextStyles.data(size: 13).copyWith(
                      fontWeight: FontWeight.bold,
                      color: CityTheme.of(context).deep,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                // 2D: the bar grows with each endorsement.
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: AppMotion.reduceOf(context) ? Duration.zero : AppMotion.emphasized,
                  curve: AppMotion.curve,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                incident.isCommunityValidated
                    ? 'Los vecinos ya validaron este reporte.'
                    : 'Faltan $missing ${missing == 1 ? 'apoyo' : 'apoyos'} para validar este reporte (+500 XP).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// "Apoyar" / "Apoyado" (HU-15): icon and text change with the state, never color alone.
  /// The thumb jumps and its ring fills a tenth (2D); a slow request shows the
  /// dotted spinner around it (8D).
  Widget _buildEndorseButton(BuildContext context, IncidentDetailState state, Incident incident) {
    final endorsed = state.viewerEndorsed;
    final onPressed = state.isEndorsing ? null : () => _toggleEndorsement(context, state);
    final scheme = Theme.of(context).colorScheme;
    final foreground = endorsed ? scheme.onSurface : scheme.onPrimary;

    final icon = Stack(
      key: _thumbKey,
      alignment: Alignment.center,
      children: [
        EndorseThumb(
          icon: LucideIcons.thumbsUp,
          count: incident.upvotesCount,
          target: Incident.validationTarget,
          endorsed: endorsed,
          color: foreground,
          burstColor: CityTheme.of(context).deep,
        ),
        if (state.isEndorsing)
          DottedSpinner(size: AppSizes.endorseRing, color: foreground, semanticLabel: 'Guardando tu apoyo'),
      ],
    );

    return SizedBox(
      width: double.infinity,
      child: endorsed
          ? PressScale(
              child: OutlinedButton.icon(onPressed: onPressed, icon: icon, label: const Text('Apoyado')),
            )
          : PressScale(
              child: FilledButton.icon(onPressed: onPressed, icon: icon, label: const Text('Apoyar este reporte')),
            ),
    );
  }

  Widget _buildProblemCard(BuildContext context, Incident incident, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            incident.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            incident.description,
            style: theme.textTheme.bodyMedium,
          ),
          if (incident.estimatedDimensions != null && incident.estimatedDimensions!.isNotEmpty) ...[
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Icon(LucideIcons.ruler, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Dimensiones estimadas: ${incident.estimatedDimensions}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, Incident incident, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.mapPin, color: CityTheme.of(context).deep, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Ubicación georreferenciada',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${incident.formattedAddress}, ${incident.neighborhood}',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            incident.city,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${incident.coordinates.latitude.toStringAsFixed(5)}°, ${incident.coordinates.longitude.toStringAsFixed(5)}°',
            style: AppTextStyles.data(size: 13).copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorCard(BuildContext context, Incident incident, ThemeData theme) {
    final authorName = incident.reporterName ?? 'Ciudadano anónimo';
    final rankName = incident.reporterRankName ?? 'Guardián Vial';
    final dateStr =
        '${incident.createdAt.day.toString().padLeft(2, '0')}/${incident.createdAt.month.toString().padLeft(2, '0')}/${incident.createdAt.year}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const RankSeal(level: 1, size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authorName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$rankName · Registrado el $dateStr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_colors.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_text_styles.dart';
import 'package:vigia_app/core/widgets/app_notice.dart';
import 'package:vigia_app/core/widgets/dotted_spinner.dart';
import 'package:vigia_app/core/widgets/primary_button.dart';
import 'package:vigia_app/core/widgets/rank_seal.dart';
import 'package:vigia_app/core/widgets/sign_in_required_dialog.dart';
import 'package:vigia_app/core/widgets/validation_seal.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_photo.dart';
import '../bloc/incident_detail_bloc.dart';
import '../bloc/incident_detail_event.dart';
import '../bloc/incident_detail_state.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del reporte', style: AppTextStyles.appBarTitle),
        centerTitle: false,
      ),
      body: BlocListener<IncidentDetailBloc, IncidentDetailState>(
        listenWhen: (previous, current) =>
            current.endorsementError != null && previous.endorsementError != current.endorsementError,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.endorsementError!)));
        },
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
              return const Center(
                child: DottedSpinner(size: 36, semanticLabel: 'Cargando reporte vial...'),
              );

            // An empty case falls through in Dart: loading needs its own body,
            // or the screen shows the failure view until the report arrives.
            case IncidentDetailStatus.loading:
              return const Center(
                child: DottedSpinner(size: 36, semanticLabel: 'Cargando reporte vial...'),
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
    );
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
            _buildEndorseButton(context, state),
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
                  color: theme.colorScheme.primary,
                ),
              ),
              _buildSeverityChip(incident.severity, theme),
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
                    Icon(Icons.info_outline, size: 14, color: semantic.info),
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

  Widget _buildSeverityChip(IncidentSeverity severity, ThemeData theme) {
    String symbol;
    Color color;

    switch (severity) {
      case IncidentSeverity.low:
        symbol = '●';
        color = const Color(0xFF266A70);
        break;
      case IncidentSeverity.medium:
        symbol = '▲';
        color = const Color(0xFFE8B03A);
        break;
      case IncidentSeverity.high:
        symbol = '◆';
        color = const Color(0xFFC2410C);
        break;
      case IncidentSeverity.critical:
        symbol = '🛑';
        color = const Color(0xFF8F1D2C);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text(
            severity.labelSpanish,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

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
            Icon(Icons.photo_library_outlined, size: 48, color: theme.colorScheme.outline),
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
                      const Icon(Icons.broken_image_outlined, size: 40),
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
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
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
  Widget _buildEndorseButton(BuildContext context, IncidentDetailState state) {
    final endorsed = state.viewerEndorsed;
    final onPressed = state.isEndorsing ? null : () => _toggleEndorsement(context, state);

    return SizedBox(
      width: double.infinity,
      child: endorsed
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.thumb_up, size: AppSizes.icon),
              label: const Text('Apoyado'),
            )
          : FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.thumb_up_outlined, size: AppSizes.icon),
              label: const Text('Apoyar este reporte'),
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
                Icon(Icons.straighten_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
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
              Icon(Icons.location_on, color: theme.colorScheme.primary, size: 22),
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

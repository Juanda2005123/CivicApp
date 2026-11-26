import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/severity_colors.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/city/city_motion.dart';
import '../../../../core/widgets/dotted_spinner.dart';
import '../../../../core/widgets/rank_seal.dart';
import '../../../../core/widgets/severity_chip.dart';
import '../../../reports/domain/entities/feed_incident.dart';
import '../../../reports/domain/entities/incident.dart';
import 'incident_map_marker.dart' show categoryIconData;

/// Card of a report in the community feed (HU-19, design system "Tarjeta de
/// reporte"): cover photo (or the category icon when there is none), severity
/// and neighborhood, title, author with rank seal, status, and the counters of
/// supports and comments. The whole card is one tap target that opens the detail.
class FeedIncidentCard extends StatelessWidget {
  final FeedIncident incident;

  /// Meters from the citizen to the report; null hides it (no GPS position).
  final double? distanceMeters;
  final VoidCallback onTap;

  const FeedIncidentCard({
    super.key,
    required this.incident,
    this.distanceMeters,
    required this.onTap,
  });

  /// "350 m" under a kilometer, "1,2 km" from there on.
  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  /// Day, month and year, as the report detail writes them.
  static String formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final distance = distanceMeters;
    final author = incident.reporterName ?? 'Ciudadano anónimo';
    final isClosedOrValidated =
        incident.status == IncidentStatus.communityValidated || incident.status == IncidentStatus.resolved;

    // One spoken description for the whole card instead of a dozen fragments.
    final spoken = [
      'Reporte ${incident.trackingCode}',
      incident.title,
      'gravedad ${incident.severity.labelSpanish}',
      'barrio ${incident.neighborhood}',
      'estado ${incident.status.labelSpanish}',
      if (distance != null) 'a ${formatDistance(distance)}',
      '${incident.upvotesCount} apoyos',
      '${incident.commentsCount} comentarios',
    ].join(', ');

    return PressScale(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          container: true,
          label: spoken,
          excludeSemantics: true,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Cover(incident: incident),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SeverityChip(level: incident.severity.level),
                          Text(
                            [incident.neighborhood, if (distance != null) 'a ${formatDistance(distance)}']
                                .where((part) => part.isNotEmpty)
                                .join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(incident.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          RankSeal(level: incident.reporterRankId ?? 1, size: AppSizes.iconLarge),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              [author, if (incident.reporterRankName != null) incident.reporterRankName!].join(' · '),
                              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Counter(icon: LucideIcons.thumbsUp, count: incident.upvotesCount),
                          _Counter(icon: LucideIcons.messageCircle, count: incident.commentsCount),
                          AppStatusChip(label: incident.status.labelSpanish, met: isClosedOrValidated),
                          Text(
                            formatDate(incident.createdAt),
                            style: AppTextStyles.data(size: 12, line: 16).copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Maps the domain severity to the theme's, so shared widgets never import a
/// feature's domain.
extension on IncidentSeverity {
  SeverityLevel get level => switch (this) {
        IncidentSeverity.low => SeverityLevel.low,
        IncidentSeverity.medium => SeverityLevel.medium,
        IncidentSeverity.high => SeverityLevel.high,
        IncidentSeverity.critical => SeverityLevel.critical,
      };
}

/// Cover of the card: the photo, or a reserved space with the category icon
/// (HU-19, criterion 4). The tracking code sits on it in the monospace face.
class _Cover extends StatelessWidget {
  final FeedIncident incident;

  const _Cover({required this.incident});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = incident.primaryPhotoUrl;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(categoryIconData(incident.categoryIcon), size: AppSizes.mapPin, color: scheme.onSurfaceVariant),
      ),
    );

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo == null)
            placeholder
          else
            Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: const Center(child: DottedSpinner(size: AppSizes.iconLarge)),
                );
              },
            ),
          Positioned(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: AppRadii.small,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Text(
                  incident.trackingCode,
                  style: AppTextStyles.data(size: 12, line: 16).copyWith(color: scheme.onSurface),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final IconData icon;
  final int count;

  const _Counter({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.icon, color: color),
        const SizedBox(width: AppSpacing.xs + 2),
        Text('$count', style: AppTextStyles.data().copyWith(color: color)),
      ],
    );
  }
}

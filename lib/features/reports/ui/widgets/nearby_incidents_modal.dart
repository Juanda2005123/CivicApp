import 'package:flutter/material.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_text_styles.dart';
import 'package:vigia_app/core/theme/severity_colors.dart';
import 'package:vigia_app/core/widgets/severity_chip.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/nearby_incident.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bottom modal displaying nearby reports matching category and location (HU-09).
class NearbyIncidentsModal extends StatelessWidget {
  final List<NearbyIncident> nearbyIncidents;
  final ValueChanged<String> onEndorse;
  final VoidCallback onContinueDraft;

  const NearbyIncidentsModal({
    super.key,
    required this.nearbyIncidents,
    required this.onEndorse,
    required this.onContinueDraft,
  });

  static Future<void> show(
    BuildContext context, {
    required List<NearbyIncident> nearbyIncidents,
    required ValueChanged<String> onEndorse,
    required VoidCallback onContinueDraft,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (_) => NearbyIncidentsModal(
        nearbyIncidents: nearbyIncidents,
        onEndorse: onEndorse,
        onContinueDraft: onContinueDraft,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(LucideIcons.circleAlert, color: theme.colorScheme.error, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Daños cercanos detectados (${nearbyIncidents.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Un vecino ya podría haber reportado este mismo daño. Revisa la lista para no duplicar esfuerzos:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: nearbyIncidents.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = nearbyIncidents[index];
                  return _NearbyIncidentItem(
                    item: item,
                    onEndorse: () {
                      Navigator.of(context).pop();
                      onEndorse(item.id);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onContinueDraft();
              },
              child: const Text('Es otro daño (Continuar reporte)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyIncidentItem extends StatelessWidget {
  final NearbyIncident item;
  final VoidCallback onEndorse;

  const _NearbyIncidentItem({
    required this.item,
    required this.onEndorse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Reports without a photo (or whose photo fails to load) show the hazard icon.
    final placeholder = ColoredBox(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(LucideIcons.triangleAlert, color: theme.colorScheme.primary),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: SizedBox(
              width: 48,
              height: 48,
              child: item.primaryPhotoUrl == null
                  ? placeholder
                  : Image.network(
                      item.primaryPhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => placeholder,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.trackingCode} · a ~${item.distanceInMeters.toStringAsFixed(0)} m',
                  style: AppTextStyles.data(size: 11).copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SeverityChip(level: _levelOf(item.severity)),
                    Text(
                      item.upvotesCount == 1 ? '1 apoyo' : '${item.upvotesCount} apoyos',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            onPressed: onEndorse,
            child: const Text('Es este'),
          ),
        ],
      ),
    );
  }
}

/// `NearbyIncident.severity` keeps the database value (`HIGH`): it is read here
/// into the theme's level so the chip speaks Spanish with its shape and color.
SeverityLevel _levelOf(String dbValue) => switch (IncidentSeverity.fromDbValue(dbValue)) {
      IncidentSeverity.low => SeverityLevel.low,
      IncidentSeverity.medium => SeverityLevel.medium,
      IncidentSeverity.high => SeverityLevel.high,
      IncidentSeverity.critical => SeverityLevel.critical,
    };

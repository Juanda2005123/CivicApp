import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../explore/ui/widgets/feed_incident_card.dart';
import '../../../reports/domain/entities/feed_incident.dart';

/// "Mis reportes" (HU-23, criterion 5): the reports the citizen published,
/// newest first, drawn with the same card as the community feed. Tapping one
/// opens its detail; with none, an invitation to publish the first.
class MyReportsSection extends StatelessWidget {
  final List<FeedIncident> reports;
  final ValueChanged<FeedIncident> onOpen;
  final VoidCallback onReportFirst;

  const MyReportsSection({
    super.key,
    required this.reports,
    required this.onOpen,
    required this.onReportFirst,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text('Mis reportes', style: theme.textTheme.titleMedium)),
        const SizedBox(height: AppSpacing.sm),
        if (reports.isEmpty)
          _EmptyInvitation(onReportFirst: onReportFirst)
        else
          for (final report in reports) ...[
            FeedIncidentCard(incident: report, onTap: () => onOpen(report)),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

class _EmptyInvitation extends StatelessWidget {
  final VoidCallback onReportFirst;

  const _EmptyInvitation({required this.onReportFirst});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Aún no has publicado reportes.', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cuando reportes un daño aparecerá aquí y podrás seguir los apoyos que recibe.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onReportFirst,
              icon: const Icon(LucideIcons.mapPinPlus, size: AppSizes.icon),
              label: const Text('Reportar mi primer daño'),
            ),
          ],
        ),
      ),
    );
  }
}

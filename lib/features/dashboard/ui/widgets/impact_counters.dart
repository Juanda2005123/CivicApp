import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/civic_impact.dart';

/// The four impact counters of "Mi perfil" (HU-23, criterion 2) in a 2 x 2 grid:
/// an icon, the number in monospace and what it counts. Each tile is read as one
/// sentence ("12 apoyos recibidos").
class ImpactCounters extends StatelessWidget {
  final CivicImpact impact;

  const ImpactCounters({super.key, required this.impact});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(
          _CounterTile(
            icon: LucideIcons.mapPinPlus,
            value: impact.reportsCreated,
            label: 'Reportes creados',
          ),
          _CounterTile(
            icon: LucideIcons.thumbsUp,
            value: impact.endorsementsReceived,
            label: 'Apoyos recibidos',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _row(
          _CounterTile(
            icon: LucideIcons.handHeart,
            value: impact.endorsementsGiven,
            label: 'Apoyos otorgados',
          ),
          _CounterTile(
            icon: LucideIcons.messageCircle,
            value: impact.commentsPublished,
            label: 'Comentarios publicados',
          ),
        ),
      ],
    );
  }

  /// Two tiles of the same height, even when one label wraps.
  Widget _row(Widget left, Widget right) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _CounterTile({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Semantics(
        container: true,
        label: '$value ${label.toLowerCase()}',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: AppSizes.iconLarge, color: context.semantic.accent),
              const SizedBox(height: AppSpacing.sm),
              Text('$value', style: AppTextStyles.data(size: 24, line: 32)),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

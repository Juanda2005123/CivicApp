import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// "Reporte validado por la comunidad" stamp (HU-16): a report that reached 10
/// endorsements. Shape (ring and check), color (the secondary clay) and text say
/// the same thing, so color is never the only signal. It stays after the count
/// drops under 10: the validation is already consolidated.
class ValidationSeal extends StatelessWidget {
  /// Endorsements the report has now, shown in monospace under the title.
  final int endorsements;

  const ValidationSeal({super.key, required this.endorsements});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;

    return Semantics(
      container: true,
      label: 'Reporte validado por la comunidad, $endorsements apoyos',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadii.medium,
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: AppSizes.touchTarget - AppSpacing.sm,
                height: AppSizes.touchTarget - AppSpacing.sm,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(LucideIcons.badgeCheck, color: color, size: AppSizes.iconLarge),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reporte validado por la comunidad',
                      style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$endorsements apoyos',
                      style: AppTextStyles.data(size: 13).copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

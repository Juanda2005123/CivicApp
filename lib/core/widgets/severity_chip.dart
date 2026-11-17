import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/severity_colors.dart';

/// Chip of the severity of a report (design system section 3.3): the **shape**,
/// the color and the text say the level, so color is never the only signal.
/// Circle = Baja, triangle = Media, diamond = Alta, octagon = Crítica.
///
/// It is 28 dp tall at the normal text size and grows with it, so the text
/// scales to 200 % without being cut.
class SeverityChip extends StatelessWidget {
  final SeverityLevel level;

  const SeverityChip({super.key, required this.level});

  /// The text of each level (the copy deck, section 8).
  static String labelOf(SeverityLevel level) => switch (level) {
        SeverityLevel.low => 'Baja',
        SeverityLevel.medium => 'Media',
        SeverityLevel.high => 'Alta',
        SeverityLevel.critical => 'Crítica',
      };

  /// Material icon with the shape of each level (design system, section 6).
  static IconData shapeOf(SeverityLevel level) => switch (level) {
        SeverityLevel.low => Icons.circle_outlined,
        SeverityLevel.medium => Icons.change_history_outlined,
        SeverityLevel.high => Icons.diamond_outlined,
        SeverityLevel.critical => Icons.dangerous_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.severity;
    final fill = colors.fillOf(level);
    final onFill = colors.onFillOf(level);
    final label = labelOf(level);

    return Semantics(
      label: 'Gravedad $label',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.chip),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - 2),
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(AppRadii.chip)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(shapeOf(level), size: AppSizes.icon - 4, color: onFill),
            const SizedBox(width: AppSpacing.xs + 2),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: onFill,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

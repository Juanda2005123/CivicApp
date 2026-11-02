import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Small pill with a label. [met] true is the tinted success style with a
/// check; false is an outlined neutral pill (a rule still pending).
class AppStatusChip extends StatelessWidget {
  final String label;
  final bool met;

  const AppStatusChip({super.key, required this.label, this.met = true});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    final foreground = met ? semantic.success : scheme.onSurfaceVariant;

    return Container(
      height: AppSizes.chip,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - 2),
      decoration: BoxDecoration(
        color: met ? semantic.successContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: met ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (met) ...[
            Icon(Icons.check_circle_outline, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

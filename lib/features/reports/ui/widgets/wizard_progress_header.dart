import 'package:flutter/material.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';

/// Header for the 5-step reporting assistant displaying a segmented step indicator.
class WizardProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const WizardProgressHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.outline.withValues(alpha: 0.3);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (currentStep > 1)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Paso anterior',
                onPressed: onBack,
              )
            else
              const SizedBox(width: 48),
            Text(
              'Paso $currentStep de $totalSteps',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cerrar asistente',
              onPressed: onClose,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: List.generate(totalSteps, (index) {
              final isReached = index + 1 <= currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index == totalSteps - 1 ? 0 : AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isReached ? activeColor : inactiveColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

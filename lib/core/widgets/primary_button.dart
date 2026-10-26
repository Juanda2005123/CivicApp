import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'dotted_spinner.dart';

/// Full-width primary action. While [isLoading] it keeps its color, shows the
/// dotted spinner with [loadingLabel] and ignores taps (a disabled look would
/// read as "unavailable", not as "working").
class PrimaryButton extends StatelessWidget {
  final String label;
  final String? loadingLabel;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loadingLabel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: isLoading ? () {} : onPressed,
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DottedSpinner(size: 22, color: foreground, semanticLabel: loadingLabel ?? 'Cargando'),
                  const SizedBox(width: AppSpacing.sm),
                  Text(loadingLabel ?? label),
                ],
              )
            : Text(label),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/severity_colors.dart';
import 'package:vigia_app/core/widgets/severity_chip.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';

/// Renders the 4 severity levels (Baja, Media, Alta, Crítica) strictly following
/// the Design System §3.3 rule of Shape + Color + Text.
class SeverityChipSelector extends StatelessWidget {
  final IncidentSeverity selectedSeverity;
  final ValueChanged<IncidentSeverity> onSeverityChanged;

  const SeverityChipSelector({
    super.key,
    required this.selectedSeverity,
    required this.onSeverityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: IncidentSeverity.values.map((severity) {
            final isSelected = severity == selectedSeverity;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: _SeverityChip(
                  severity: severity,
                  isSelected: isSelected,
                  onTap: () => onSeverityChanged(severity),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final IncidentSeverity severity;
  final bool isSelected;
  final VoidCallback onTap;

  const _SeverityChip({
    required this.severity,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final spec = _getSeveritySpec(severity, isDark);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? spec.baseColor.withValues(alpha: isDark ? 0.22 : 0.12)
              : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(
            color: isSelected
                ? spec.baseColor
                : theme.colorScheme.outline.withValues(alpha: 0.35),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              spec.icon,
              size: spec.iconSize,
              color: isSelected ? spec.baseColor : spec.baseColor.withValues(alpha: 0.7),
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                spec.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? (isDark ? Colors.white : spec.baseColor)
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SeverityVisualSpec _getSeveritySpec(IncidentSeverity severity, bool isDark) {
    switch (severity) {
      case IncidentSeverity.low:
        return _SeverityVisualSpec(
          label: 'Baja',
          icon: SeverityChip.shapeOf(SeverityLevel.low),
          iconSize: 10,
          baseColor: isDark ? const Color(0xFF3E9AA2) : const Color(0xFF266A70),
        );
      case IncidentSeverity.medium:
        return _SeverityVisualSpec(
          label: 'Media',
          icon: SeverityChip.shapeOf(SeverityLevel.medium),
          iconSize: 12,
          baseColor: isDark ? const Color(0xFFF2C66A) : const Color(0xFFC7830B),
        );
      case IncidentSeverity.high:
        return _SeverityVisualSpec(
          label: 'Alta',
          icon: SeverityChip.shapeOf(SeverityLevel.high),
          iconSize: 11,
          baseColor: isDark ? const Color(0xFFF08A57) : const Color(0xFFC2410C),
        );
      case IncidentSeverity.critical:
        return _SeverityVisualSpec(
          label: 'Crítica',
          icon: SeverityChip.shapeOf(SeverityLevel.critical),
          iconSize: 14,
          baseColor: isDark ? const Color(0xFFE56B7B) : const Color(0xFFB91C1C),
        );
    }
  }
}

class _SeverityVisualSpec {
  final String label;
  final IconData icon;
  final double iconSize;
  final Color baseColor;

  const _SeverityVisualSpec({
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.baseColor,
  });
}

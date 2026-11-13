import 'package:flutter/material.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = _getSeveritySpec(severity, isDark);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? spec.bgColor : spec.bgColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isSelected ? spec.bgColor : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
            width: isSelected ? 2.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  spec.shapeSymbol,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? spec.textColor : spec.bgColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    spec.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isSelected ? spec.textColor : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                  ),
                ),
              ],
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
          shapeSymbol: '●',
          bgColor: isDark ? const Color(0xFF3E9AA2) : const Color(0xFF266A70),
          textColor: Colors.white,
        );
      case IncidentSeverity.medium:
        return _SeverityVisualSpec(
          label: 'Media',
          shapeSymbol: '▲',
          bgColor: isDark ? const Color(0xFFF2C66A) : const Color(0xFFE8B03A),
          textColor: const Color(0xFF10364A),
        );
      case IncidentSeverity.high:
        return _SeverityVisualSpec(
          label: 'Alta',
          shapeSymbol: '◆',
          bgColor: isDark ? const Color(0xFFF08A57) : const Color(0xFFC2410C),
          textColor: Colors.white,
        );
      case IncidentSeverity.critical:
        return _SeverityVisualSpec(
          label: 'Crítica',
          shapeSymbol: '🛑',
          bgColor: isDark ? const Color(0xFFE56B7B) : const Color(0xFF8F1D2C),
          textColor: Colors.white,
        );
    }
  }
}

class _SeverityVisualSpec {
  final String label;
  final String shapeSymbol;
  final Color bgColor;
  final Color textColor;

  const _SeverityVisualSpec({
    required this.label,
    required this.shapeSymbol,
    required this.bgColor,
    required this.textColor,
  });
}

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/city_theme.dart';
import 'city_motion.dart';
import 'flag_stripe.dart';

/// A city with its own pack as a photo card: registration offers one per city.
/// The selected one is told by the accent border, a check and its spoken state,
/// not by color alone.
class CityPhotoCard extends StatelessWidget {
  final CityShowcase city;
  final bool selected;

  /// Short tag in the corner ("Detectada por GPS").
  final String? tag;
  final VoidCallback? onTap;

  const CityPhotoCard({super.key, required this.city, required this.selected, required this.onTap, this.tag});

  static const double _selectedBorder = 3;

  @override
  Widget build(BuildContext context) {
    final theme = CityTheme.of(context);
    final photo = city.card;
    final note = tag;

    return PressScale(
      enabled: onTap != null,
      child: Semantics(
        button: true,
        selected: selected,
        enabled: onTap != null,
        label: [city.name, city.department, ?note].join(', '),
        onTap: onTap,
        excludeSemantics: true,
        child: ClipRRect(
          borderRadius: AppRadii.medium,
          child: Material(
            color: city.veil,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                children: [
                  if (photo != null)
                    Positioned.fill(
                      child: Ink.image(
                        image: photo,
                        fit: BoxFit.cover,
                        onImageError: (_, _) {},
                      ),
                    ),
                  // Veil from the side of the text.
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            city.veil.withValues(alpha: 0.94),
                            city.veil.withValues(alpha: 0.75),
                            city.veil.withValues(alpha: 0.15),
                          ],
                          stops: const [0, 0.55, 1],
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppSizes.cityCard, minWidth: double.infinity),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(city.name, style: AppTextStyles.cityCard.copyWith(color: CityTheme.onVeil)),
                          Text(
                            city.department,
                            style: AppTextStyles.data(size: 11, line: 16).copyWith(color: CityTheme.onVeil),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              FlagStripe(flag: city.flag),
                              if (note != null) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs / 2,
                                    ),
                                    decoration: BoxDecoration(color: theme.accent, borderRadius: AppRadii.small),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.locateFixed, size: AppSpacing.md, color: theme.onAccent),
                                        const SizedBox(width: AppSpacing.xs),
                                        Flexible(
                                          child: Text(
                                            note,
                                            style: AppTextStyles.data(size: 10, line: 14)
                                                .copyWith(color: theme.onAccent),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selected) ...[
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(color: theme.accent, shape: BoxShape.circle),
                        child: Icon(LucideIcons.check, size: AppSizes.icon, color: theme.onAccent),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: AppRadii.medium,
                            border: Border.all(color: theme.accent, width: _selectedBorder),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/city_theme.dart';

/// The flag of the active city as a short stripe, one segment per band. Nothing
/// is drawn for a look without a flag. It is decoration: screen readers skip it.
class FlagStripe extends StatelessWidget {
  /// Bands to draw; the active city's when null.
  final List<CityFlagBand>? flag;
  final double width;
  final double height;

  /// Thin border that keeps a white band visible on a light surface.
  final bool outlined;

  const FlagStripe({
    super.key,
    this.flag,
    this.width = AppSizes.flagWidth,
    this.height = AppSizes.flagHeight,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final bands = flag ?? CityTheme.of(context).flag;
    if (bands.isEmpty) return const SizedBox.shrink();

    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppSpacing.xs / 2)),
        foregroundDecoration: outlined
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.xs / 2),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
              )
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final band in bands) Expanded(flex: band.weight, child: ColoredBox(color: band.color)),
          ],
        ),
      ),
    );
  }
}

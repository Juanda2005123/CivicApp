import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'brand_seal.dart';

/// Seal + "VIGÍA" wordmark + tagline, centered. Used by the splash and the
/// login. Set [onInk] on the ink splash, where text is always cream.
class BrandMark extends StatelessWidget {
  final double sealSize;
  final double wordmarkSize;
  final String? tagline;
  final bool onInk;

  const BrandMark({
    super.key,
    this.sealSize = 72,
    this.wordmarkSize = 32,
    this.tagline,
    this.onInk = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wordColor = onInk ? AppColors.cream : scheme.onSurface;
    final taglineColor = onInk ? AppColors.onSurfaceVariantDark : scheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandSeal(size: sealSize, variant: onInk ? SealVariant.onDark : SealVariant.auto),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text('VIGÍA', style: AppTextStyles.wordmark(wordmarkSize).copyWith(color: wordColor)),
        ),
        if (tagline != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(tagline!, style: AppTextStyles.bodySmall.copyWith(color: taglineColor)),
        ],
      ],
    );
  }
}

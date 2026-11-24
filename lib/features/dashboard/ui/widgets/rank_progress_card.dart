import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/rank_seal.dart';
import '../../domain/entities/rank_progress.dart';

/// Progress toward the next civic rank (HU-23, criteria 3 and 4): the current
/// seal, the points, a 6 dp bar and a sentence that says what is missing. At
/// the highest rank the bar is full and the sentence says so.
class RankProgressCard extends StatelessWidget {
  final RankProgress progress;

  const RankProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = progress.next;
    final percent = (progress.fraction * 100).round();

    final caption = next == null
        ? 'Llegaste al nivel más alto. Gracias por vigilar tu ciudad.'
        : 'Te faltan ${progress.xpMissing} pts para el Nivel ${next.id} · ${next.name}.';
    final target = next == null ? '${progress.experiencePoints} pts' : '${progress.experiencePoints} / ${next.minXp} pts';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RankSeal(
                  level: progress.current.id,
                  size: 40,
                  semanticLabel: 'Nivel ${progress.current.id}, ${progress.current.name}',
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu avance', style: theme.textTheme.titleMedium),
                      Text(
                        'Nivel actual: ${progress.current.id}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              label: 'Progreso hacia el siguiente nivel',
              value: '$percent por ciento',
              child: ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: AppRadii.small,
                  child: LinearProgressIndicator(value: progress.fraction, minHeight: 6),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(target, style: AppTextStyles.data(size: 14, line: 20)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

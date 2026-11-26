import 'package:flutter/material.dart';
import 'package:vigia_app/core/theme/app_colors.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_text_styles.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_resolution.dart';

/// Who is looking at a repair proposal decides which actions the card offers.
enum ResolutionViewerRole { guest, neighbor, proponent, author }

/// Pinned card of the pending repair proposal, on top of the discussion
/// (RN-11): the photo, the description, who proposed it, the progress of the
/// votes and the actions of the viewer. Green border and a "En verificación"
/// label, so it never relies on color alone.
class ResolutionProposalCard extends StatelessWidget {
  final IncidentResolution resolution;
  final ResolutionViewerRole role;
  final bool hasVoted;
  final bool isBusy;
  final DateTime now;
  final VoidCallback onConfirm;
  final VoidCallback onObject;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const ResolutionProposalCard({
    super.key,
    required this.resolution,
    required this.role,
    required this.hasVoted,
    required this.now,
    required this.onConfirm,
    required this.onObject,
    required this.onAccept,
    required this.onReject,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final proponent = resolution.proponentName ?? 'Ciudadano anónimo';
    final daysLeft = resolution.expiresAt.difference(now).inHours ~/ 24 + 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadii.medium,
        border: Border.all(color: semantic.success, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: semantic.successContainer,
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.build_circle_outlined, size: 16, color: semantic.success),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Reparación en verificación',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: semantic.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                daysLeft <= 1 ? 'Vence hoy' : 'Vence en $daysLeft días',
                style: AppTextStyles.data(size: 12).copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppRadii.small,
            child: Image.network(
              resolution.photoUrl,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              semanticLabel: 'Foto de la reparación enviada por $proponent',
              errorBuilder: (context, error, stackTrace) => Container(
                height: 120,
                alignment: Alignment.center,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(resolution.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Propuesta de $proponent',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          _VoteProgress(
            label: 'Confirmaciones',
            value: resolution.confirmations,
            color: semantic.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          _VoteProgress(
            label: 'Objeciones',
            value: resolution.objections,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActions(context, theme),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    final note = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    switch (role) {
      case ResolutionViewerRole.author:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Un vecino dice que tu reporte ya fue reparado. ¿Es cierto?', style: note),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onReject,
                    icon: const Icon(Icons.close, size: AppSizes.icon),
                    label: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : onAccept,
                    icon: const Icon(Icons.check, size: AppSizes.icon),
                    label: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ],
        );
      case ResolutionViewerRole.proponent:
        return Text(
          'Es tu propuesta. Si 3 vecinos la confirman, el reporte queda resuelto y ganas +50 XP.',
          style: note,
        );
      case ResolutionViewerRole.guest:
      case ResolutionViewerRole.neighbor:
        if (hasVoted) {
          return Row(
            children: [
              Icon(Icons.how_to_vote_outlined, size: AppSizes.icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text('Ya votaste esta propuesta. Gracias por verificar.', style: note)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('¿Pasaste por ahí? Ayuda a verificar si la vía de verdad quedó bien.', style: note),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onObject,
                    icon: const Icon(Icons.report_outlined, size: AppSizes.icon),
                    label: const Text('Objetar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isBusy ? null : onConfirm,
                    icon: const Icon(Icons.verified_outlined, size: AppSizes.icon),
                    label: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}

/// "Confirmaciones 2 de 3" with a bar; the number is always written out.
class _VoteProgress extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _VoteProgress({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const target = IncidentResolution.quorum;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            Text(
              '${value.clamp(0, target)} de $target',
              style: AppTextStyles.data(size: 13).copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: AppRadii.small,
          child: LinearProgressIndicator(
            value: (value / target).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: theme.colorScheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

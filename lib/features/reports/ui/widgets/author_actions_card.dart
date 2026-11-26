import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/incident.dart';
import 'package:vigia_app/core/widgets/city/city_motion.dart';

/// What the author sees on their own report (HU-18, RN-03): "Editar" and
/// "Eliminar" while the report is inside its 30 minutes and has fewer than 5
/// endorsements, and a note that it is frozen afterwards. A timer checks the
/// clock every few seconds so the buttons go away by themselves when the window
/// closes with the screen open; the server enforces the rule anyway.
class AuthorActionsCard extends StatefulWidget {
  final Incident incident;
  final String viewerId;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// How often the card looks at the clock again. Tests shorten it.
  final Duration checkEvery;

  const AuthorActionsCard({
    super.key,
    required this.incident,
    required this.viewerId,
    required this.onEdit,
    required this.onDelete,
    this.isDeleting = false,
    this.checkEvery = const Duration(seconds: 15),
  });

  /// "12 min" or "menos de 1 min", rounding up so it never says 0 while time is left.
  static String formatTimeLeft(Duration left) {
    final minutes = (left.inSeconds / 60).ceil();
    return minutes <= 1 ? 'menos de 1 min' : '$minutes min';
  }

  @override
  State<AuthorActionsCard> createState() => _AuthorActionsCardState();
}

class _AuthorActionsCardState extends State<AuthorActionsCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.checkEvery, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final incident = widget.incident;
    final editable = incident.canBeModifiedBy(widget.viewerId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: editable ? _buildActions(theme, incident) : _buildFrozen(theme, scheme),
      ),
    );
  }

  Widget _buildActions(ThemeData theme, Incident incident) {
    final left = AuthorActionsCard.formatTimeLeft(incident.editTimeLeft());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text('Tu reporte', style: theme.textTheme.titleMedium)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Puedes editarlo o eliminarlo durante $left más, mientras tenga menos de ${Incident.editEndorsementLimit} apoyos.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: PressScale(child: OutlinedButton.icon(
                onPressed: widget.isDeleting ? null : widget.onEdit,
                icon: const Icon(LucideIcons.pencil, size: AppSizes.icon),
                label: const Text('Editar'),
              )),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PressScale(child: OutlinedButton.icon(
                onPressed: widget.isDeleting ? null : widget.onDelete,
                icon: const Icon(LucideIcons.trash2, size: AppSizes.icon),
                label: Text(widget.isDeleting ? 'Eliminando…' : 'Eliminar'),
              )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrozen(ThemeData theme, ColorScheme scheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.lock, size: AppSizes.iconLarge, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reporte congelado', style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ya pasaron los ${Incident.editWindow.inMinutes} minutos o el reporte tiene '
                '${Incident.editEndorsementLimit} apoyos o más, así que no se puede editar ni eliminar. '
                'Así se protege la evidencia de la comunidad.',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

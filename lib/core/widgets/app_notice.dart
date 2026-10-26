import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum NoticeKind { error, success, info }

/// Inline message with an icon, a text and the color of its state. The state is
/// never conveyed by color alone.
class AppNotice extends StatelessWidget {
  final String message;
  final NoticeKind kind;
  final IconData? icon;

  const AppNotice({super.key, required this.message, this.kind = NoticeKind.info, this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    final (background, foreground, defaultIcon) = switch (kind) {
      NoticeKind.error => (scheme.errorContainer, scheme.onErrorContainer, Icons.error_outline),
      NoticeKind.success => (semantic.successContainer, semantic.success, Icons.check_circle_outline),
      NoticeKind.info => (semantic.infoContainer, semantic.info, Icons.info_outline),
    };

    return Semantics(
      liveRegion: kind == NoticeKind.error,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: background, borderRadius: AppRadii.small),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? defaultIcon, size: AppSizes.icon, color: foreground),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

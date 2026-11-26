import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_spacing.dart';

/// Modal shown when the user blocked the location permission (HU-29): it
/// explains how to unblock it and offers to open the system settings. Used by
/// registration, the map and Step 1 of the report wizard.
Future<void> showLocationBlockedDialog(
  BuildContext context, {
  required String message,
  required VoidCallback onOpenSettings,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(LucideIcons.locateOff),
      title: const Text('Ubicación bloqueada'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Ahora no'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            onOpenSettings();
          },
          icon: const Icon(LucideIcons.settings, size: AppSizes.icon),
          label: const Text('Abrir ajustes'),
        ),
      ],
    ),
  );
}

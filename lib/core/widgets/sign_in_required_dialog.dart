import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Modal shown when a guest (HU-22) tries an action that needs an account,
/// such as reporting a damage: it explains why and offers to sign in or to
/// create an account, without performing the action.
Future<void> showSignInRequiredDialog(
  BuildContext context, {
  required String message,
  required VoidCallback onSignIn,
  required VoidCallback onRegister,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.lock_outline),
      title: const Text('Necesitas iniciar sesión'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Ahora no'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            onRegister();
          },
          child: const Text('Crear cuenta'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            onSignIn();
          },
          icon: const Icon(Icons.login, size: AppSizes.icon),
          label: const Text('Iniciar sesión'),
        ),
      ],
    ),
  );
}

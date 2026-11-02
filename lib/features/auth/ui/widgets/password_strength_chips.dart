import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../domain/validators/password_policy.dart';

/// Live checklist of the password rules. It only draws the [checks] it is
/// given; the rules themselves live in `PasswordPolicy`.
class PasswordStrengthChips extends StatelessWidget {
  final PasswordChecks checks;

  const PasswordStrengthChips({super.key, required this.checks});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm - 2,
      runSpacing: AppSpacing.sm - 2,
      children: [
        AppStatusChip(label: '6+ caracteres', met: checks.hasMinLength),
        AppStatusChip(label: 'Una mayúscula', met: checks.hasUppercase),
        AppStatusChip(label: 'Una minúscula', met: checks.hasLowercase),
        AppStatusChip(label: 'Un número', met: checks.hasNumber),
      ],
    );
  }
}

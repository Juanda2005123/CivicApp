import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/validators/password_policy.dart';

/// Live checklist of the password rules. It only draws the [checks] it is
/// given; the rules themselves live in `PasswordPolicy`.
class PasswordStrengthChips extends StatelessWidget {
  final PasswordChecks checks;

  const PasswordStrengthChips({super.key, required this.checks});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _Chip(label: '6+ caracteres', satisfied: checks.hasMinLength),
        _Chip(label: 'Mayúscula (A-Z)', satisfied: checks.hasUppercase),
        _Chip(label: 'Minúscula (a-z)', satisfied: checks.hasLowercase),
        _Chip(label: 'Número (0-9)', satisfied: checks.hasNumber),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool satisfied;

  const _Chip({required this.label, required this.satisfied});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: satisfied
            ? AppTheme.statusSuccessBg
            : const Color(0xFFF1F5F9), // Slate 100
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: satisfied
              ? AppTheme.statusSuccessBorder
              : const Color(0xFFE2E8F0), // Slate 200
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.circle_outlined,
            size: 11,
            color: satisfied ? AppTheme.statusSuccess : AppTheme.slate400,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: satisfied ? FontWeight.w600 : FontWeight.normal,
              color: satisfied ? AppTheme.statusSuccess : AppTheme.slate600,
            ),
          ),
        ],
      ),
    );
  }
}

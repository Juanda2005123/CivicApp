/// Result of evaluating a password against [PasswordPolicy].
class PasswordChecks {
  final bool hasMinLength;
  final bool hasLowercase;
  final bool hasUppercase;
  final bool hasNumber;

  const PasswordChecks({
    required this.hasMinLength,
    required this.hasLowercase,
    required this.hasUppercase,
    required this.hasNumber,
  });

  bool get isValid => hasMinLength && hasLowercase && hasUppercase && hasNumber;
}

/// Single source of the password rules: the use case enforces them and the
/// form uses [evaluate] for the live checklist.
class PasswordPolicy {
  static const int minLength = 6;

  static PasswordChecks evaluate(String password) {
    return PasswordChecks(
      hasMinLength: password.length >= minLength,
      hasLowercase: RegExp(r'[a-z]').hasMatch(password),
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasNumber: RegExp(r'[0-9]').hasMatch(password),
    );
  }

  /// Returns the first broken rule as a message, or `null` when valid.
  static String? validate(String? password) {
    if (password == null || password.isEmpty) return 'Escribe una contraseña';
    final checks = evaluate(password);
    if (!checks.hasMinLength) return 'Usa al menos $minLength caracteres';
    if (!checks.hasLowercase) return 'Incluye una letra minúscula';
    if (!checks.hasUppercase) return 'Incluye una letra mayúscula';
    if (!checks.hasNumber) return 'Incluye un número';
    return null;
  }
}

/// Business rules for the registration fields (RN auth/onboarding).
class RegistrationRules {
  /// Full name: at least a first and a last name. Any run of whitespace
  /// counts as one separator, so "Juan  " is a single word.
  static String? validateFullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Escribe tu nombre completo';
    if (name.split(RegExp(r'\s+')).length < 2) {
      return 'Escribe tu nombre y apellido';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Escribe tu correo';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Escribe un correo válido';
    }
    return null;
  }
}

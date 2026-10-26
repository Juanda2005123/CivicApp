/// Business rules for the registration fields (RN auth/onboarding).
class RegistrationRules {
  /// Full name: at least a first and a last name. Any run of whitespace
  /// counts as one separator, so "Juan  " is a single word.
  static String? validateFullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Please enter your full name';
    if (name.split(RegExp(r'\s+')).length < 2) {
      return 'Please enter at least a first and last name';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter an email address';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}

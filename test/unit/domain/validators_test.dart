import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/validators/password_policy.dart';
import 'package:vigia_app/features/auth/domain/validators/registration_rules.dart';

void main() {
  group('PasswordPolicy', () {
    test('evaluate reports each rule independently', () {
      final checks = PasswordPolicy.evaluate('abc');
      expect(checks.hasMinLength, isFalse);
      expect(checks.hasLowercase, isTrue);
      expect(checks.hasUppercase, isFalse);
      expect(checks.hasNumber, isFalse);
      expect(checks.isValid, isFalse);
    });

    test('validate returns the first broken rule', () {
      expect(PasswordPolicy.validate(null), 'Escribe una contraseña');
      expect(PasswordPolicy.validate('Ab1'), contains('al menos 6'));
      expect(PasswordPolicy.validate('ABCDEF1'), contains('minúscula'));
      expect(PasswordPolicy.validate('abcdef1'), contains('mayúscula'));
      expect(PasswordPolicy.validate('Abcdefg'), contains('número'));
      expect(PasswordPolicy.validate('Abc123'), isNull);
    });
  });

  group('RegistrationRules', () {
    test('full name needs two words, counting any whitespace run as one separator', () {
      expect(RegistrationRules.validateFullName(''), isNotNull);
      expect(RegistrationRules.validateFullName('Juan'), isNotNull);
      expect(RegistrationRules.validateFullName('Juan  '), isNotNull);
      expect(RegistrationRules.validateFullName('Juan David'), isNull);
      expect(RegistrationRules.validateFullName('Juan   David'), isNull);
    });

    test('email must look like name@domain.tld', () {
      expect(RegistrationRules.validateEmail(''), isNotNull);
      expect(RegistrationRules.validateEmail('a@b'), isNotNull);
      expect(RegistrationRules.validateEmail('a b@c.co'), isNotNull);
      expect(RegistrationRules.validateEmail('ana@example.com'), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_up_usecase.dart';

import '../../support/fakes.dart';

void main() {
  late List<String> calls;
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late SignUpUseCase signUp;

  setUp(() {
    calls = [];
    auth = FakeAuthRepository(calls: calls);
    profiles = FakeProfileRepository(calls: calls);
    signUp = SignUpUseCase(auth, profiles);
  });

  Future<void> register({
    String fullName = 'Ana Gomez',
    String email = 'ana@example.com',
    String password = 'Abc123',
    String city = 'Cali',
  }) {
    return signUp(fullName: fullName, email: email, password: password, cityName: city);
  }

  test('creates the Auth account first and then the profile with the returned id', () async {
    final profile = await signUp(
      fullName: '  Ana Gomez ',
      email: ' ana@example.com ',
      password: 'Abc123',
      cityName: 'Cali',
    );

    expect(calls, ['auth.signUp', 'profile.create']);
    expect(profile.id, 'uid-1');
    expect(profile.fullName, 'Ana Gomez');
    expect(profile.email, 'ana@example.com');
    expect(profile.cityName, 'Cali');
    expect(profiles.stored['uid-1'], profile);
  });

  group('validation happens before any service is called', () {
    final cases = <String, Future<void> Function()>{
      'one-word name': () => register(fullName: 'Ana'),
      'name with trailing spaces only': () => register(fullName: 'Ana   '),
      'invalid email': () => register(email: 'not-an-email'),
      'weak password': () => register(password: 'abc'),
      'password without uppercase': () => register(password: 'abc123'),
      'empty city': () => register(city: ' '),
    };
    for (final entry in cases.entries) {
      test(entry.key, () async {
        await expectLater(entry.value(), throwsA(isA<Exception>()));
        expect(calls, isEmpty);
      });
    }
  });

  test('propagates Auth errors and never creates the profile', () async {
    auth.signUpError = Exception('This email is already registered');

    await expectLater(register(), throwsA(isA<Exception>()));
    expect(calls, ['auth.signUp']);
  });

  test('signs out and explains when the profile cannot be saved', () async {
    profiles.createError = Exception('permission denied');

    await expectLater(
      register(),
      throwsA(predicate((e) => e.toString().contains('no pudimos guardar tu perfil'))),
    );
    expect(calls, ['auth.signUp', 'profile.create', 'auth.signOut']);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_out_usecase.dart';

import '../../support/fakes.dart';

void main() {
  late List<String> calls;
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;

  setUp(() {
    calls = [];
    auth = FakeAuthRepository(calls: calls);
    profiles = FakeProfileRepository(calls: calls)..stored['uid-1'] = caliProfile;
  });

  group('SignInUseCase', () {
    test('validates credentials with Auth and then loads the profile', () async {
      final profile = await SignInUseCase(auth, profiles)(
        email: ' ana@example.com ',
        password: 'Abc123',
      );

      expect(calls, ['auth.signIn', 'profile.get']);
      expect(profile, caliProfile);
    });

    test('rejects empty fields without calling Auth', () async {
      await expectLater(
        SignInUseCase(auth, profiles)(email: '', password: ''),
        throwsA(isA<Exception>()),
      );
      expect(calls, isEmpty);
    });

    test('propagates invalid credentials and never loads the profile', () async {
      auth.signInError = Exception('Invalid credentials');

      await expectLater(
        SignInUseCase(auth, profiles)(email: 'ana@example.com', password: 'bad'),
        throwsA(isA<Exception>()),
      );
      expect(calls, ['auth.signIn']);
    });

    test('signs out and rethrows when the account has no profile', () async {
      profiles.stored.clear();

      await expectLater(
        SignInUseCase(auth, profiles)(email: 'ana@example.com', password: 'Abc123'),
        throwsA(isA<Exception>()),
      );
      expect(calls, ['auth.signIn', 'profile.get', 'auth.signOut']);
    });
  });

  group('GetCurrentProfileUseCase', () {
    test('returns null when nobody is signed in', () async {
      expect(await GetCurrentProfileUseCase(auth, profiles)(), isNull);
      expect(calls, isEmpty);
    });

    test('returns the profile of the persisted session', () async {
      auth.user = const AuthUser(id: 'uid-1', email: 'ana@example.com');

      expect(await GetCurrentProfileUseCase(auth, profiles)(), caliProfile);
    });
  });

  test('SignOutUseCase ends the session', () async {
    auth.user = const AuthUser(id: 'uid-1', email: 'ana@example.com');

    await SignOutUseCase(auth)();

    expect(calls, ['auth.signOut']);
    expect(auth.currentUser(), isNull);
  });
}

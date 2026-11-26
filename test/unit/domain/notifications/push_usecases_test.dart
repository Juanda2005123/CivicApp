import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:vigia_app/features/notifications/domain/usecases/enable_push_usecase.dart';
import 'package:vigia_app/features/notifications/domain/usecases/watch_opened_reports_usecase.dart';

import '../../../support/fake_push_repository.dart';
import '../../../support/fakes.dart';

void main() {
  late FakePushRepository push;
  final signedIn = FakeAuthRepository(user: const AuthUser(id: 'ana', email: 'ana@correo.com'));

  setUp(() {
    push = FakePushRepository();
  });

  group('EnablePushUseCase (HU-24)', () {
    test('subscribes the signed-in citizen', () async {
      expect(await EnablePushUseCase(signedIn, push)(), isTrue);
      expect(push.calls, ['push.enable ana']);
    });

    test('a guest has no pushes', () async {
      expect(await EnablePushUseCase(FakeAuthRepository(), push)(), isFalse);
      expect(push.calls, isEmpty);
    });

    test('a failure never stops the app (criterion 4)', () async {
      push.enableError = Exception('Sin Google Play');

      expect(await EnablePushUseCase(signedIn, push)(), isFalse);
    });
  });

  group('WatchOpenedReportsUseCase', () {
    test('ignores empty report ids', () async {
      final ids = WatchOpenedReportsUseCase(push)().toList();
      push.opened
        ..add('inc-1')
        ..add('  ')
        ..add('inc-2');
      await push.opened.close();

      expect(await ids, ['inc-1', 'inc-2']);
    });
  });

  group('SignOutUseCase', () {
    test('this device stops receiving the citizen pushes before signing out', () async {
      final auth = FakeAuthRepository(user: const AuthUser(id: 'ana', email: 'ana@correo.com'));

      await SignOutUseCase(auth, push)();

      expect(push.calls, ['push.disable ana']);
      expect(auth.calls, contains('auth.signOut'));
    });

    test('a push failure never blocks signing out', () async {
      final auth = FakeAuthRepository(user: const AuthUser(id: 'ana', email: 'ana@correo.com'));
      push.disableError = Exception('Sin conexión');

      await SignOutUseCase(auth, push)();

      expect(auth.calls, contains('auth.signOut'));
    });
  });
}

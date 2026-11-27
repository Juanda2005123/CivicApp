import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/notifications/domain/usecases/enable_push_usecase.dart';
import 'package:vigia_app/features/notifications/domain/usecases/watch_opened_reports_usecase.dart';
import 'package:vigia_app/features/notifications/ui/bloc/push_bloc.dart';
import 'package:vigia_app/features/notifications/ui/bloc/push_event.dart';

import '../../../support/fake_push_repository.dart';
import '../../../support/fakes.dart';

void main() {
  late FakePushRepository push;

  PushBloc bloc({bool guest = false}) {
    final auth = FakeAuthRepository(user: guest ? null : const AuthUser(id: 'ana', email: 'ana@correo.com'));
    final created = PushBloc(EnablePushUseCase(auth, push), WatchOpenedReportsUseCase(push));
    addTearDown(created.close);
    return created;
  }

  setUp(() {
    push = FakePushRepository();
  });

  test('PushStarted turns on the citizen pushes', () async {
    final pushes = bloc()..add(const PushStarted());
    await pumpEventQueue();

    expect(pushes.state.enabled, isTrue);
    expect(push.calls, ['push.enable ana']);
  });

  test('a guest stays without pushes', () async {
    final pushes = bloc(guest: true)..add(const PushStarted());
    await pumpEventQueue();

    expect(pushes.state.enabled, isFalse);
  });

  test('every tapped push reports its report, the same one twice too (criterion 3)', () async {
    final pushes = bloc()..add(const PushStarted());
    await pumpEventQueue();

    push.opened.add('inc-1');
    await pumpEventQueue();
    expect(pushes.state.openedIncidentId, 'inc-1');
    expect(pushes.state.openedCount, 1);

    push.opened.add('inc-1');
    await pumpEventQueue();
    expect(pushes.state.openedCount, 2);
  });
}

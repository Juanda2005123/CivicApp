import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/notifications/domain/usecases/enable_push_usecase.dart';
import 'package:vigia_app/features/notifications/domain/usecases/watch_opened_reports_usecase.dart';
import 'package:vigia_app/features/notifications/ui/bloc/push_bloc.dart';
import 'package:vigia_app/features/notifications/ui/bloc/push_event.dart';
import 'package:vigia_app/features/notifications/ui/widgets/push_opened_listener.dart';

import '../../support/fake_push_repository.dart';
import '../../support/fakes.dart';

void main() {
  testWidgets('tapping a push opens that report on top of the shell (HU-24, criterion 3)', (tester) async {
    final push = FakePushRepository();
    final auth = FakeAuthRepository(user: const AuthUser(id: 'ana', email: 'ana@correo.com'));
    final bloc = PushBloc(EnablePushUseCase(auth, push), WatchOpenedReportsUseCase(push))..add(const PushStarted());
    addTearDown(bloc.close);

    await tester.pumpWidget(MaterialApp(
      routes: {
        AppRoutes.reportDetail: (context) =>
            Text('Detalle ${ModalRoute.of(context)!.settings.arguments}'),
      },
      home: BlocProvider.value(
        value: bloc,
        child: const PushOpenedListener(child: Text('Shell')),
      ),
    ));
    await tester.pump();

    push.opened.add('inc-42');
    await tester.pumpAndSettle();

    expect(find.text('Detalle inc-42'), findsOneWidget);
    // Ends the listening of the bloc, so the test can finish.
    await push.opened.close();
    await tester.pump();
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/theme/theme_cubit.dart';
import 'package:vigia_app/core/widgets/dotted_spinner.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_event.dart';
import 'package:vigia_app/features/dashboard/ui/screens/dashboard_screen.dart';

import '../support/fakes.dart';

Widget createDashboardTestWidget(ProfileBloc bloc) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
      BlocProvider<ProfileBloc>.value(value: bloc..add(ProfileStarted())),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const DashboardScreen(),
      routes: {
        AppRoutes.login: (context) => const Scaffold(body: Text('Login Screen Mock')),
      },
    ),
  );
}

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;

  // Created inside each test: a bloc built in setUp would run its event loop in
  // the real zone, outside the widget tester's fake async.
  ProfileBloc newBloc() {
    final created = ProfileBloc(GetCurrentProfileUseCase(auth, profiles), SignOutUseCase(auth));
    addTearDown(created.close);
    return created;
  }

  const citizen = Profile(
    id: 'uid-1',
    email: 'juand@vigia.co',
    fullName: 'Juan David Quintero',
    cityName: 'Cali',
    rankName: 'Observador Urbano',
  );

  setUp(() {
    auth = FakeAuthRepository(user: const AuthUser(id: 'uid-1', email: 'juand@vigia.co'));
    profiles = FakeProfileRepository()..stored['uid-1'] = citizen;
  });



  group('DashboardScreen Widget Tests', () {
    testWidgets('renders all citizen profile details from the bloc state', (tester) async {
      await tester.pumpWidget(createDashboardTestWidget(newBloc()));
      await tester.pumpAndSettle();

      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Sesión activa'), findsOneWidget);
      expect(find.text('Rango cívico'), findsOneWidget);
      expect(find.text('Juan David Quintero'), findsOneWidget);
      expect(find.text('juand@vigia.co'), findsOneWidget);
      expect(find.text('Cali'), findsOneWidget);
      expect(find.text('Nivel 1 · Observador Urbano'), findsOneWidget);
      expect(find.text('0 pts'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('shows a progress indicator while the profile loads', (tester) async {
      final gate = profiles.gate = Completer<void>();
      await tester.pumpWidget(createDashboardTestWidget(newBloc()));
      await tester.pump();

      expect(find.byType(DottedSpinner), findsOneWidget);
      expect(find.text('Rango cívico'), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(DottedSpinner), findsNothing);
      expect(find.text('Juan David Quintero'), findsOneWidget);
    });

    testWidgets('tapping logout ends the session and navigates to login', (tester) async {
      await tester.pumpWidget(createDashboardTestWidget(newBloc()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Cerrar sesión'));
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(auth.calls, contains('auth.signOut'));
      expect(auth.currentUser(), isNull);
      expect(find.text('Login Screen Mock'), findsOneWidget);
    });

    testWidgets('a profile that cannot load shows the message and a retry button', (tester) async {
      profiles.getError = Exception('No pudimos cargar tu perfil: permission denied');
      await tester.pumpWidget(createDashboardTestWidget(newBloc()));
      await tester.pumpAndSettle();

      expect(find.text('No pudimos cargar tu perfil: permission denied'), findsOneWidget);

      profiles.getError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Juan David Quintero'), findsOneWidget);
    });
  });
}

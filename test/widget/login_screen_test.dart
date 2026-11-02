import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/theme/theme_cubit.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:vigia_app/features/auth/ui/bloc/login_bloc.dart';
import 'package:vigia_app/features/auth/ui/screens/login_screen.dart';

import '../support/fakes.dart';

Widget createLoginTestWidget(LoginBloc bloc) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
      BlocProvider<LoginBloc>.value(value: bloc),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const LoginScreen(),
      routes: {
        AppRoutes.register: (context) => const Scaffold(body: Text('Register Screen Mock')),
        AppRoutes.dashboard: (context) => const Scaffold(body: Text('Dashboard Screen Mock')),
      },
    ),
  );
}

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;

  LoginBloc newBloc() {
    final created = LoginBloc(SignInUseCase(auth, profiles));
    addTearDown(created.close);
    return created;
  }

  setUp(() {
    final calls = <String>[];
    auth = FakeAuthRepository(calls: calls);
    profiles = FakeProfileRepository(calls: calls)..stored['uid-1'] = caliProfile;
    // Blocs are created inside each test: one built in setUp would run its event
    // loop in the real zone, outside the widget tester's fake async.
  });



  group('LoginScreen Widget Tests', () {
    testWidgets('renders all visual elements and inputs', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(newBloc()));
      await tester.pumpAndSettle();

      expect(find.text('VIGÍA'), findsOneWidget);
      expect(find.text('Tu voz, con evidencia.'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.text('Regístrate'), findsOneWidget);
    });

    testWidgets('triggers validation errors when submitting empty form', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(newBloc()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(find.text('Escribe tu correo'), findsOneWidget);
      expect(find.text('Escribe tu contraseña'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('validates invalid email format and short password', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(newBloc()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'correo_invalido');
      await tester.enterText(find.byType(TextField).at(1), '123');

      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(find.text('Escribe un correo válido'), findsOneWidget);
      expect(find.text('La contraseña debe tener al menos 6 caracteres'), findsOneWidget);
    });

    testWidgets('toggles password visibility when clicking eye icon', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(newBloc()));
      await tester.pumpAndSettle();

      final eyeIcon = find.byIcon(Icons.visibility_outlined);
      expect(eyeIcon, findsOneWidget);

      await tester.tap(eyeIcon);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('clicking Register here navigates to register route', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(newBloc()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Regístrate'));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen Mock'), findsOneWidget);
    });

    testWidgets('valid credentials sign in and land on the dashboard', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(newBloc()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'ana@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'Abc123');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(auth.calls, ['auth.signIn', 'profile.get']);
      expect(find.text('Dashboard Screen Mock'), findsOneWidget);
    });

    testWidgets('invalid credentials show the error and stay on the login', (tester) async {
      auth.signInError = Exception('Correo o contraseña incorrectos. Revisa tus datos e inténtalo de nuevo.');
      await tester.pumpWidget(createLoginTestWidget(newBloc()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'ana@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'Abc123');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(
        find.text('Correo o contraseña incorrectos. Revisa tus datos e inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Dashboard Screen Mock'), findsNothing);
    });
  });
}

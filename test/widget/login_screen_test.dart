import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:vigia_app/features/auth/ui/bloc/login_bloc.dart';
import 'package:vigia_app/features/auth/ui/screens/login_screen.dart';

import '../support/fakes.dart';

Widget createLoginTestWidget(LoginBloc bloc) {
  return BlocProvider<LoginBloc>.value(
    value: bloc,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
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
      expect(find.text('Civic Road Infrastructure Auditing Platform'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Register here'), findsOneWidget);
    });

    testWidgets('triggers validation errors when submitting empty form', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(newBloc()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(auth.calls, isEmpty);
    });

    testWidgets('validates invalid email format and short password', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(newBloc()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'correo_invalido');
      await tester.enterText(find.byType(TextFormField).at(1), '123');

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
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

      await tester.tap(find.text('Register here'));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen Mock'), findsOneWidget);
    });

    testWidgets('valid credentials sign in and land on the dashboard', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(newBloc()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'ana@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Abc123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(auth.calls, ['auth.signIn', 'profile.get']);
      expect(find.text('Dashboard Screen Mock'), findsOneWidget);
    });

    testWidgets('invalid credentials show the error and stay on the login', (tester) async {
      auth.signInError = Exception('Invalid credentials. Please verify your email and password.');
      await tester.pumpWidget(createLoginTestWidget(newBloc()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'ana@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'Abc123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Invalid credentials. Please verify your email and password.'),
        findsOneWidget,
      );
      expect(find.text('Dashboard Screen Mock'), findsNothing);
    });
  });
}

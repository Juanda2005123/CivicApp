import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/auth/domain/entities/user.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:vigia_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:vigia_app/features/auth/presentation/screens/login_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<User> login({required String email, required String password}) async {
    return User(
      id: 'test-1',
      email: email,
      fullName: 'Prueba Login',
      residenceCityId: 1,
      cityName: 'Cali',
      rankId: 1,
      reputationPoints: 0,
    );
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required int cityId,
    String? cityName,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<Usuario?> getCurrentUser() async => null;
}

Widget createLoginTestWidget(AuthCubit cubit) {
  return BlocProvider<AuthCubit>.value(
    value: cubit,
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
  late _FakeAuthRepository repository;
  late AuthCubit authCubit;

  setUp(() {
    repository = _FakeAuthRepository();
    authCubit = AuthCubit(
      loginUseCase: LoginUseCase(repository),
      registerUseCase: RegisterUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      getCurrentUserUseCase: GetCurrentUserUseCase(repository),
    );
  });

  tearDown(() {
    authCubit.close();
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('renders all visual elements and inputs', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(authCubit));
      await tester.pumpAndSettle();

      expect(find.text('VIGÍA'), findsOneWidget);
      expect(find.text('Civic Road Infrastructure Auditing Platform'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Register here'), findsOneWidget);
    });

    testWidgets('triggers validation errors when submitting empty form', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(authCubit));
      await tester.pumpAndSettle();

      // Click Log In button without typing
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('validates invalid email format and short password', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(authCubit));
      await tester.pumpAndSettle();

      // Enter invalid email and short password
      await tester.enterText(find.byType(TextFormField).at(0), 'correo_invalido');
      await tester.enterText(find.byType(TextFormField).at(1), '123');

      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('toggles password visibility when clicking eye icon', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(authCubit));
      await tester.pumpAndSettle();

      final eyeIcon = find.byIcon(Icons.visibility_outlined);
      expect(eyeIcon, findsOneWidget);

      await tester.tap(eyeIcon);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('clicking Register here navigates to register route', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(authCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register here'));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen Mock'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/auth/domain/entities/usuario.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:vigia_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:vigia_app/features/auth/presentation/screens/login_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Usuario> login({required String email, required String password}) async {
    return Usuario(
      id: 'test-1',
      email: email,
      nombreCompleto: 'Prueba Login',
      ciudadResidenciaId: 1,
      ciudadNombre: 'Cali',
      nivelReputacionId: 1,
      puntosReputacion: 0,
    );
  }

  @override
  Future<Usuario> register({
    required String email,
    required String password,
    required String nombreCompleto,
    required int ciudadId,
    String? ciudadNombre,
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
      expect(find.text('Plataforma de Auditoría Vial y Veeduría Ciudadana'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Regístrate aquí'), findsOneWidget);
    });

    testWidgets('triggers validation errors when submitting empty form', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(authCubit));
      await tester.pumpAndSettle();

      // Click Iniciar Sesión button without typing
      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    });

    testWidgets('validates invalid email format and short password', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(authCubit));
      await tester.pumpAndSettle();

      // Enter invalid email and short password
      await tester.enterText(find.byType(TextFormField).at(0), 'correo_invalido');
      await tester.enterText(find.byType(TextFormField).at(1), '123');

      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
      expect(find.text('La contraseña debe tener al menos 6 caracteres'), findsOneWidget);
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

    testWidgets('clicking Regístrate aquí navigates to register route', (tester) async {
      await tester.pumpWidget(createLoginTestWidget(authCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Regístrate aquí'));
      await tester.pumpAndSettle();

      expect(find.text('Register Screen Mock'), findsOneWidget);
    });
  });
}

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
import 'package:vigia_app/features/auth/presentation/screens/register_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Usuario> login({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<Usuario> register({
    required String email,
    required String password,
    required String nombreCompleto,
    required int ciudadId,
    String? ciudadNombre,
  }) async {
    return Usuario(
      id: 'reg-1',
      email: email,
      nombreCompleto: nombreCompleto,
      ciudadResidenciaId: ciudadId,
      ciudadNombre: ciudadNombre ?? 'Cali',
      nivelReputacionId: 1,
      puntosReputacion: 0,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<Usuario?> getCurrentUser() async => null;
}

Widget createRegisterTestWidget(AuthCubit cubit) {
  return BlocProvider<AuthCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const RegisterScreen(),
      routes: {
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

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders all registration fields and placeholder', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRegisterTestWidget(authCubit));
      await tester.pumpAndSettle();

      expect(find.text('Registro de Ciudadano'), findsOneWidget);
      expect(find.text('Únete a la Veeduría Cívica'), findsOneWidget);
      expect(find.text('Ej. Juan David Quintero'), findsOneWidget);
      expect(find.text('Ciudad de Residencia (Cobertura DANE)'), findsOneWidget);
      expect(find.text('Detectar ciudad más cercana por GPS'), findsOneWidget);
      expect(find.text('Crear Cuenta Cívica'), findsOneWidget);
    });

    testWidgets('validates full name requiring at least two words', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRegisterTestWidget(authCubit));
      await tester.pumpAndSettle();

      // Enter only a single word
      await tester.enterText(find.byType(TextFormField).at(0), 'Juan');
      await tester.ensureVisible(find.text('Crear Cuenta Cívica'));
      await tester.tap(find.text('Crear Cuenta Cívica'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa al menos un nombre y un apellido'), findsOneWidget);
    });

    testWidgets('enforces strict password complexity rules (uppercase, lowercase, number)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRegisterTestWidget(authCubit));
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField).at(2);
      final submitButton = find.text('Crear Cuenta Cívica');

      // 1. Too short
      await tester.enterText(passwordField, 'Ab1');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.text('Debe contener al menos 6 caracteres'), findsOneWidget);

      // 2. Missing uppercase
      await tester.enterText(passwordField, 'abcdef1');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.text('Debe contener al menos una letra mayúscula'), findsOneWidget);

      // 3. Missing lowercase
      await tester.enterText(passwordField, 'ABCDEF1');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.text('Debe contener al menos una letra minúscula'), findsOneWidget);

      // 4. Missing number
      await tester.enterText(passwordField, 'Abcdefg');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
      expect(find.text('Debe contener al menos un número'), findsOneWidget);
    });

    testWidgets('validates password confirmation match', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createRegisterTestWidget(authCubit));
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField).at(2);
      final confirmField = find.byType(TextFormField).at(3);
      final submitButton = find.text('Crear Cuenta Cívica');

      await tester.enterText(passwordField, 'Password123');
      await tester.enterText(confirmField, 'Different123');

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });
  });
}

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
import 'package:vigia_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:vigia_app/features/auth/presentation/screens/dashboard_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  bool logoutCalled = false;

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
  }) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<Usuario?> getCurrentUser() async => null;
}

Widget createDashboardTestWidget(AuthCubit cubit) {
  return BlocProvider<AuthCubit>.value(
    value: cubit,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const DashboardScreen(),
      routes: {
        AppRoutes.login: (context) => const Scaffold(body: Text('Login Screen Mock')),
      },
    ),
  );
}

void main() {
  late _FakeAuthRepository repository;
  late AuthCubit authCubit;

  final testCitizen = const Usuario(
    id: 'user-777',
    email: 'juand@vigia.co',
    nombreCompleto: 'Juan David Quintero',
    ciudadResidenciaId: 1,
    ciudadNombre: 'Cali (Valle del Cauca)',
    nivelReputacionId: 1,
    nivelReputacionNombre: 'Observador',
    puntosReputacion: 0,
  );

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

  group('DashboardScreen Widget Tests', () {
    testWidgets('renders all citizen profile details correctly', (tester) async {
      authCubit.emit(Authenticated(testCitizen));

      await tester.pumpWidget(createDashboardTestWidget(authCubit));
      await tester.pumpAndSettle();

      expect(find.text('Panel Cívico VIGÍA'), findsOneWidget);
      expect(find.text('¡Te has logueado con éxito!'), findsOneWidget);
      expect(find.text('Resumen del Perfil Cívico'), findsOneWidget);
      expect(find.text('Juan David Quintero'), findsOneWidget);
      expect(find.text('juand@vigia.co'), findsOneWidget);
      expect(find.text('Cali (Valle del Cauca)'), findsOneWidget);
      expect(find.text('Observador (Rango 1)'), findsOneWidget);
      expect(find.text('0 pts'), findsOneWidget);
      expect(find.text('Salir / Desloguearse'), findsOneWidget);
    });

    testWidgets('tapping logout button triggers cubit logout and navigates to login', (tester) async {
      authCubit.emit(Authenticated(testCitizen));

      await tester.pumpWidget(createDashboardTestWidget(authCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salir / Desloguearse'));
      await tester.pumpAndSettle();

      expect(repository.logoutCalled, isTrue);
      expect(find.text('Login Screen Mock'), findsOneWidget);
    });
  });
}

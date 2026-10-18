import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/usuario.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/register_usecase.dart';
import 'package:vigia_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:vigia_app/features/auth/presentation/cubit/auth_state.dart';

class _MockRepoForCubit implements AuthRepository {
  bool shouldFail = false;

  final testUser = const Usuario(
    id: 'test-id',
    email: 'test@vigia.co',
    nombreCompleto: 'Prueba Cubit',
    ciudadResidenciaId: 1,
    ciudadNombre: 'Cali',
    nivelReputacionId: 1,
    puntosReputacion: 0,
  );

  @override
  Future<Usuario> login({required String email, required String password}) async {
    if (shouldFail) throw Exception('Credenciales incorrectas');
    return testUser;
  }

  @override
  Future<Usuario> register({
    required String email,
    required String password,
    required String nombreCompleto,
    required int ciudadId,
    String? ciudadNombre,
  }) async {
    if (shouldFail) throw Exception('Correo duplicado');
    return testUser;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<Usuario?> getCurrentUser() async {
    return shouldFail ? null : testUser;
  }
}

void main() {
  late _MockRepoForCubit repository;
  late AuthCubit cubit;

  setUp(() {
    repository = _MockRepoForCubit();
    cubit = AuthCubit(
      loginUseCase: LoginUseCase(repository),
      registerUseCase: RegisterUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      getCurrentUserUseCase: GetCurrentUserUseCase(repository),
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('AuthCubit State Transitions', () {
    test('Initial state is AuthInitial', () {
      expect(cubit.state, const AuthInitial());
    });

    test('login emits [AuthLoading, Authenticated] upon successful credentials', () async {
      final expectedStates = [
        const AuthLoading(),
        Authenticated(repository.testUser),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.login(email: 'test@vigia.co', password: 'Password123');
    });

    test('login emits [AuthLoading, AuthError] upon failure', () async {
      repository.shouldFail = true;

      final expectedStates = [
        const AuthLoading(),
        isA<AuthError>(),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.login(email: 'test@vigia.co', password: 'wrong');
    });

    test('register emits [AuthLoading, Authenticated] on success', () async {
      final expectedStates = [
        const AuthLoading(),
        Authenticated(repository.testUser),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.register(
        email: 'test@vigia.co',
        password: 'Password123',
        nombreCompleto: 'Prueba Cubit',
        ciudadId: 1,
      );
    });

    test('logout emits [AuthLoading, AuthUnauthenticated]', () async {
      final expectedStates = [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.logout();
    });

    test('checkAuthStatus emits [AuthLoading, Authenticated] when session exists', () async {
      final expectedStates = [
        const AuthLoading(),
        Authenticated(repository.testUser),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.checkAuthStatus();
    });
  });
}

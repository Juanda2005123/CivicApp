import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/usuario.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/register_usecase.dart';

class _FakeAuthRepository implements AuthRepository {
  Usuario? _currentUser;
  bool logoutCalled = false;

  @override
  Future<Usuario> login({required String email, required String password}) async {
    if (password == 'wrong') {
      throw Exception('Credenciales incorrectas');
    }
    final user = Usuario(
      id: 'mock-user-id',
      email: email,
      nombreCompleto: 'Juan David Quintero',
      ciudadResidenciaId: 1,
      ciudadNombre: 'Cali (Valle del Cauca)',
      nivelReputacionId: 1,
      puntosReputacion: 0,
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<Usuario> register({
    required String email,
    required String password,
    required String nombreCompleto,
    required int ciudadId,
    String? ciudadNombre,
  }) async {
    final user = Usuario(
      id: 'new-user-id',
      email: email,
      nombreCompleto: nombreCompleto,
      ciudadResidenciaId: ciudadId,
      ciudadNombre: ciudadNombre ?? 'Cali',
      nivelReputacionId: 1,
      puntosReputacion: 0,
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    _currentUser = null;
  }

  @override
  Future<Usuario?> getCurrentUser() async {
    return _currentUser;
  }
}

void main() {
  late _FakeAuthRepository repository;
  late LoginUseCase loginUseCase;
  late RegisterUseCase registerUseCase;
  late LogoutUseCase logoutUseCase;
  late GetCurrentUserUseCase getCurrentUserUseCase;

  setUp(() {
    repository = _FakeAuthRepository();
    loginUseCase = LoginUseCase(repository);
    registerUseCase = RegisterUseCase(repository);
    logoutUseCase = LogoutUseCase(repository);
    getCurrentUserUseCase = GetCurrentUserUseCase(repository);
  });

  group('Domain Layer Use Cases Isolation Tests', () {
    test('LoginUseCase successfully delegates to repository and returns Usuario entity', () async {
      final user = await loginUseCase(email: 'test@vigia.co', password: 'Password123');

      expect(user.id, 'mock-user-id');
      expect(user.email, 'test@vigia.co');
      expect(user.nombreCompleto, 'Juan David Quintero');
      expect(user.nivelReputacionNombre, 'Observador');
    });

    test('LoginUseCase propagates repository exceptions', () async {
      expect(
        () => loginUseCase(email: 'test@vigia.co', password: 'wrong'),
        throwsException,
      );
    });

    test('RegisterUseCase successfully creates citizen and returns Usuario entity', () async {
      final user = await registerUseCase(
        email: 'nuevo@vigia.co',
        password: 'Password123',
        nombreCompleto: 'Andrés López',
        ciudadId: 1,
        ciudadNombre: 'Cali',
      );

      expect(user.id, 'new-user-id');
      expect(user.email, 'nuevo@vigia.co');
      expect(user.nombreCompleto, 'Andrés López');
      expect(user.ciudadResidenciaId, 1);
    });

    test('GetCurrentUserUseCase returns null when no user is logged in', () async {
      final user = await getCurrentUserUseCase();
      expect(user, isNull);
    });

    test('LogoutUseCase executes successfully and clears current session', () async {
      await loginUseCase(email: 'test@vigia.co', password: 'Password123');
      expect(await getCurrentUserUseCase(), isNotNull);

      await logoutUseCase();
      expect(repository.logoutCalled, isTrue);
      expect(await getCurrentUserUseCase(), isNull);
    });
  });
}

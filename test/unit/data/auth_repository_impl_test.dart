import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vigia_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vigia_app/features/auth/data/models/usuario_model.dart';
import 'package:vigia_app/features/auth/data/repositories/auth_repository_impl.dart';

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  bool shouldThrowInvalidCredentials = false;
  bool shouldThrowUserAlreadyRegistered = false;
  bool shouldThrowNetworkError = false;
  bool shouldThrowGenericError = false;

  final testModel = const UsuarioModel(
    id: 'user-123',
    email: 'test@vigia.co',
    nombreCompleto: 'Ciudadano Modelo',
    ciudadResidenciaId: 1,
    ciudadNombre: 'Cali',
    nivelReputacionId: 1,
    nivelReputacionNombre: 'Observador',
    puntosReputacion: 0,
    activo: true,
  );

  @override
  SupabaseClient get supabaseClient => throw UnimplementedError();

  @override
  Future<UsuarioModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _checkErrors();
    return testModel;
  }

  @override
  Future<UsuarioModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required int cityId,
    String? cityName,
  }) async {
    _checkErrors();
    return testModel;
  }

  @override
  Future<void> signOut() async {
    _checkErrors();
  }

  @override
  Future<UsuarioModel?> getCurrentUser() async {
    if (shouldThrowGenericError) throw Exception('Database unreachable');
    return testModel;
  }

  void _checkErrors() {
    if (shouldThrowInvalidCredentials) {
      throw Exception('Invalid login credentials: AuthApiException');
    }
    if (shouldThrowUserAlreadyRegistered) {
      throw Exception('User already registered');
    }
    if (shouldThrowNetworkError) {
      throw Exception('SocketException: Failed host lookup');
    }
    if (shouldThrowGenericError) {
      throw Exception('Internal database error');
    }
  }
}

void main() {
  late _FakeAuthRemoteDataSource remoteDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    remoteDataSource = _FakeAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: remoteDataSource);
  });

  group('AuthRepositoryImpl Data Layer Tests', () {
    test('login returns domain Usuario entity on success', () async {
      final user = await repository.login(email: 'test@vigia.co', password: 'Password123');

      expect(user.id, 'user-123');
      expect(user.email, 'test@vigia.co');
      expect(user.nombreCompleto, 'Ciudadano Modelo');
    });

    test('login translates invalid credentials to friendly civic exception', () async {
      remoteDataSource.shouldThrowInvalidCredentials = true;

      expect(
        () => repository.login(email: 'test@vigia.co', password: 'wrong'),
        throwsA(predicate((e) =>
            e.toString().contains('Credenciales incorrectas. Verifica tu correo y contraseña.'))),
      );
    });

    test('register translates duplicate user error to friendly exception', () async {
      remoteDataSource.shouldThrowUserAlreadyRegistered = true;

      expect(
        () => repository.register(
          email: 'dup@vigia.co',
          password: 'Password123',
          nombreCompleto: 'Duplicado',
          ciudadId: 1,
        ),
        throwsA(predicate((e) =>
            e.toString().contains('Este correo ya está registrado en VIGÍA.'))),
      );
    });

    test('translates network socket error to friendly connection message', () async {
      remoteDataSource.shouldThrowNetworkError = true;

      expect(
        () => repository.login(email: 'test@vigia.co', password: 'Password123'),
        throwsA(predicate((e) =>
            e.toString().contains('Error de conexión a internet. Revisa tu red.'))),
      );
    });

    test('getCurrentUser returns null when datasource fails', () async {
      remoteDataSource.shouldThrowGenericError = true;
      final user = await repository.getCurrentUser();
      expect(user, isNull);
    });
  });
}

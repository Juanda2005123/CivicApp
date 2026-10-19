import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vigia_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vigia_app/features/auth/data/models/user_model.dart';
import 'package:vigia_app/features/auth/data/repositories/auth_repository_impl.dart';

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  bool shouldThrowInvalidCredentials = false;
  bool shouldThrowUserAlreadyRegistered = false;
  bool shouldThrowNetworkError = false;
  bool shouldThrowGenericError = false;

  final testModel = const UserModel(
    id: 'user-123',
    email: 'test@vigia.co',
    fullName: 'Ciudadano Modelo',
    residenceCityId: 1,
    cityName: 'Cali',
    rankId: 1,
    rankName: 'Urban Observer',
    reputationPoints: 0,
    isActive: true,
  );

  @override
  SupabaseClient get supabaseClient => throw UnimplementedError();

  @override
  Future<UserModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _checkErrors();
    return testModel;
  }

  @override
  Future<UserModel> signUp({
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
  Future<UserModel?> getCurrentUser() async {
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
    test('login returns domain User entity on success', () async {
      final user = await repository.login(email: 'test@vigia.co', password: 'Password123');

      expect(user.id, 'user-123');
      expect(user.email, 'test@vigia.co');
      expect(user.fullName, 'Ciudadano Modelo');
    });

    test('login translates invalid credentials to friendly civic exception', () async {
      remoteDataSource.shouldThrowInvalidCredentials = true;

      expect(
        () => repository.login(email: 'test@vigia.co', password: 'wrong'),
        throwsA(predicate((e) =>
            e.toString().contains('Invalid credentials. Please verify your email and password.'))),
      );
    });

    test('register translates duplicate user error to friendly exception', () async {
      remoteDataSource.shouldThrowUserAlreadyRegistered = true;

      expect(
        () => repository.register(
          email: 'dup@vigia.co',
          password: 'Password123',
          fullName: 'Duplicado',
          cityId: 1,
        ),
        throwsA(predicate((e) =>
            e.toString().contains('This email is already registered in VIGÍA.'))),
      );
    });

    test('translates network socket error to friendly connection message', () async {
      remoteDataSource.shouldThrowNetworkError = true;

      expect(
        () => repository.login(email: 'test@vigia.co', password: 'Password123'),
        throwsA(predicate((e) =>
            e.toString().contains('Internet connection error. Please check your network connection.'))),
      );
    });

    test('getCurrentUser returns null when datasource fails', () async {
      remoteDataSource.shouldThrowGenericError = true;
      final user = await repository.getCurrentUser();
      expect(user, isNull);
    });
  });
}

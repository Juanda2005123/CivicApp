import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/user.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/register_usecase.dart';

class _FakeAuthRepository implements AuthRepository {
  User? _currentUser;
  bool logoutCalled = false;

  @override
  Future<User> login({required String email, required String password}) async {
    if (password == 'wrong') {
      throw Exception('Invalid credentials');
    }
    final user = User(
      id: 'mock-user-id',
      email: email,
      fullName: 'Juan David Quintero',
      residenceCityId: 1,
      cityName: 'Cali (Valle del Cauca)',
      rankId: 1,
      rankName: 'Urban Observer',
      reputationPoints: 0,
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required int cityId,
    String? cityName,
  }) async {
    final user = User(
      id: 'new-user-id',
      email: email,
      fullName: fullName,
      residenceCityId: cityId,
      cityName: cityName ?? 'Cali',
      rankId: 1,
      rankName: 'Urban Observer',
      reputationPoints: 0,
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
  Future<User?> getCurrentUser() async {
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
    test('LoginUseCase successfully delegates to repository and returns User entity', () async {
      final user = await loginUseCase(email: 'test@vigia.co', password: 'Password123');

      expect(user.id, 'mock-user-id');
      expect(user.email, 'test@vigia.co');
      expect(user.fullName, 'Juan David Quintero');
      expect(user.rankName, 'Urban Observer');
    });

    test('LoginUseCase propagates repository exceptions', () async {
      expect(
        () => loginUseCase(email: 'test@vigia.co', password: 'wrong'),
        throwsException,
      );
    });

    test('RegisterUseCase successfully creates citizen and returns User entity', () async {
      final user = await registerUseCase(
        email: 'new@vigia.co',
        password: 'Password123',
        fullName: 'Andres Lopez',
        cityId: 1,
        cityName: 'Cali',
      );

      expect(user.id, 'new-user-id');
      expect(user.email, 'new@vigia.co');
      expect(user.fullName, 'Andres Lopez');
      expect(user.residenceCityId, 1);
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

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/update_personal_info_usecase.dart';

class _FakeProfileRepo implements ProfileRepository {
  String? updatedName;
  String? updatedCity;

  @override
  Future<void> createProfile(Profile profile) async {}

  @override
  Future<Profile> getProfile(String id) async => throw UnimplementedError();

  @override
  Future<void> updateLastCity(String id, String cityName) async {}

  @override
  Future<void> updateProfileInfo({
    required String userId,
    required String fullName,
    required String cityName,
  }) async {
    updatedName = fullName;
    updatedCity = cityName;
  }
}

class _FakeAuthRepo implements AuthRepository {
  String? updatedEmail;
  Exception? emailError;

  @override
  AuthUser? currentUser() => const AuthUser(id: 'u1', email: 'old@vigia.co');

  @override
  Future<AuthUser> signIn({required String email, required String password}) async =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> signUp({required String email, required String password}) async =>
      throw UnimplementedError();

  @override
  Future<void> updateEmail(String newEmail) async {
    if (emailError != null) throw emailError!;
    updatedEmail = newEmail;
  }

  @override
  Future<void> updatePassword({
    required String currentEmail,
    required String currentPassword,
    required String newPassword,
  }) async {}
}

void main() {
  late _FakeProfileRepo profileRepo;
  late _FakeAuthRepo authRepo;
  late UpdatePersonalInfoUseCase useCase;

  setUp(() {
    profileRepo = _FakeProfileRepo();
    authRepo = _FakeAuthRepo();
    useCase = UpdatePersonalInfoUseCase(profileRepo, authRepo);
  });

  test('rejects full name with fewer than two words', () async {
    expect(
      () => useCase(
        userId: 'u1',
        currentEmail: 'old@vigia.co',
        fullName: 'Ana',
        cityName: 'Cali',
        email: 'old@vigia.co',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('rejects invalid email', () async {
    expect(
      () => useCase(
        userId: 'u1',
        currentEmail: 'old@vigia.co',
        fullName: 'Ana Gómez',
        cityName: 'Cali',
        email: 'not-an-email',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('updates profile without requesting email verification when email is unchanged', () async {
    final result = await useCase(
      userId: 'u1',
      currentEmail: 'old@vigia.co',
      fullName: 'Ana Gómez',
      cityName: 'Medellín',
      email: 'old@vigia.co',
    );

    expect(profileRepo.updatedName, 'Ana Gómez');
    expect(profileRepo.updatedCity, 'Medellín');
    expect(authRepo.updatedEmail, isNull);
    expect(result.emailVerificationPending, isFalse);
  });

  test('calls updateEmail and flags emailVerificationPending when email changed', () async {
    final result = await useCase(
      userId: 'u1',
      currentEmail: 'old@vigia.co',
      fullName: 'Ana Gómez',
      cityName: 'Cali',
      email: 'new@vigia.co',
    );

    expect(authRepo.updatedEmail, 'new@vigia.co');
    expect(result.emailVerificationPending, isTrue);
  });
}

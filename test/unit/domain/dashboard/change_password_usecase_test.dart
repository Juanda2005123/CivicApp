import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/change_password_usecase.dart';

class _FakeAuthRepo implements AuthRepository {
  String? updatedPassword;
  Exception? error;

  @override
  AuthUser? currentUser() => const AuthUser(id: 'u1', email: 'ana@vigia.co');

  @override
  Future<AuthUser> signIn({required String email, required String password}) async =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> signUp({required String email, required String password}) async =>
      throw UnimplementedError();

  @override
  Future<void> updateEmail(String newEmail) async {}

  @override
  Future<void> updatePassword({
    required String currentEmail,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (error != null) throw error!;
    updatedPassword = newPassword;
  }
}

void main() {
  late _FakeAuthRepo authRepo;
  late ChangePasswordUseCase useCase;

  setUp(() {
    authRepo = _FakeAuthRepo();
    useCase = ChangePasswordUseCase(authRepo);
  });

  test('rejects empty current password', () async {
    expect(
      () => useCase(
        currentEmail: 'ana@vigia.co',
        currentPassword: '',
        newPassword: 'Password1',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('rejects weak new password', () async {
    expect(
      () => useCase(
        currentEmail: 'ana@vigia.co',
        currentPassword: 'OldPassword1',
        newPassword: 'weak',
      ),
      throwsA(isA<Exception>()),
    );
  });

  test('updates password when current and new passwords are valid', () async {
    await useCase(
      currentEmail: 'ana@vigia.co',
      currentPassword: 'OldPassword1',
      newPassword: 'NewPassword2',
    );
    expect(authRepo.updatedPassword, 'NewPassword2');
  });
}

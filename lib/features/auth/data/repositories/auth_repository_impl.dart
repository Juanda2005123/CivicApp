import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<AuthUser> signUp({required String email, required String password}) =>
      _dataSource.signUp(email: email, password: password);

  @override
  Future<AuthUser> signIn({required String email, required String password}) =>
      _dataSource.signIn(email: email, password: password);

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  AuthUser? currentUser() => _dataSource.currentUser();

  @override
  Future<void> updateEmail(String newEmail) => _dataSource.updateEmail(newEmail);

  @override
  Future<void> updatePassword({
    required String currentEmail,
    required String currentPassword,
    required String newPassword,
  }) =>
      _dataSource.updatePassword(
        currentEmail: currentEmail,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
}

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Data layer implementation of the AuthRepository contract.
/// Enforces Inversion of Control (IoC) and decouples the Domain layer from Supabase.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final model = await remoteDataSource.signInWithPassword(
        email: email,
        password: password,
      );
      return model.toEntity();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required int cityId,
    String? cityName,
  }) async {
    try {
      final model = await remoteDataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        cityId: cityId,
        cityName: cityName,
      );
      return model.toEntity();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.signOut();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final model = await remoteDataSource.getCurrentUser();
      return model?.toEntity();
    } catch (_) {
      return null;
    }
  }

  Exception _handleError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return Exception('Invalid credentials. Please verify your email and password.');
    }
    if (msg.contains('user already registered') || msg.contains('already registered')) {
      return Exception('This email is already registered in VIGÍA.');
    }
    if (msg.contains('network') || msg.contains('socketexception') || msg.contains('failed host lookup')) {
      return Exception('Internet connection error. Please check your network connection.');
    }
    return Exception(error.toString().replaceAll('Exception: ', ''));
  }
}

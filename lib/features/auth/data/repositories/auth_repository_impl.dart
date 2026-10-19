import '../../domain/entities/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementación del repositorio de autenticación en la capa de datos.
/// Cumple la Inversión de Control (IoC) y desacopla el Dominio de Supabase.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Usuario> login({
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
  Future<Usuario?> getCurrentUser() async {
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
      return Exception('Credenciales incorrectas. Verifica tu correo y contraseña.');
    }
    if (msg.contains('user already registered') || msg.contains('already registered')) {
      return Exception('Este correo ya está registrado en VIGÍA.');
    }
    if (msg.contains('network') || msg.contains('socketexception') || msg.contains('failed host lookup')) {
      return Exception('Error de conexión a internet. Revisa tu red.');
    }
    return Exception(error.toString().replaceAll('Exception: ', ''));
  }
}

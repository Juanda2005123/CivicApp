import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_state.dart';

/// Cubit que administra el ciclo de vida de la sesión cívica.
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AuthInitial());

  /// Verifica si existe una sesión activa persistida
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());
    try {
      final user = await getCurrentUserUseCase();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Inicia sesión con credenciales
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await loginUseCase(email: email, password: password);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Registers a new citizen account with their official DANE coverage city
  Future<void> register({
    required String email,
    required String password,
    String? fullName,
    String? nombreCompleto,
    int? cityId,
    int? ciudadId,
    String? cityName,
    String? ciudadNombre,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await registerUseCase(
        email: email,
        password: password,
        fullName: fullName ?? nombreCompleto ?? '',
        cityId: cityId ?? ciudadId ?? 1,
        cityName: cityName ?? ciudadNombre,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Cierra la sesión activa
  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await logoutUseCase();
    } catch (_) {
      // Ignora errores de red al cerrar sesión local
    } finally {
      emit(const AuthUnauthenticated());
    }
  }
}

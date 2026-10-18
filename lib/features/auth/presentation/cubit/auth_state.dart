import 'package:equatable/equatable.dart';
import '../../domain/entities/usuario.dart';

/// Jerarquía sellada (Dart 3 sealed class) para estados de autenticación cívica.
/// Garantiza exhaustividad en tiempo de compilación según lo enseñado en las Lecciones 0045-0048.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial previo a cualquier verificación
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Estado de carga mientras se procesa la solicitud asíncrona
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Estado autenticado con la sesión cívica activa y datos del ciudadano
class Authenticated extends AuthState {
  final Usuario usuario;

  const Authenticated(this.usuario);

  @override
  List<Object?> get props => [usuario];
}

/// Estado cuando no hay ninguna sesión activa o se cerró sesión
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Estado de error con mensaje tipado para la interfaz de usuario
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

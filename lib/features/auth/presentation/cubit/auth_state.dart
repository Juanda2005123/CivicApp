import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Dart 3 sealed class hierarchy for civic authentication states.
/// Guarantees compile-time exhaustiveness matching Clean Architecture presentation standards.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state prior to any verification or auth checks
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state while processing asynchronous requests
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state with active civic session and citizen profile data
class Authenticated extends AuthState {
  final User user;

  /// Backward-compatible alias for user
  User get usuario => user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state when no session exists or user logged out
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Error state containing a user-facing typed message
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

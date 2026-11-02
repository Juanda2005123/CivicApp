import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../domain/entities/auth_user.dart';

/// The only class that talks to Supabase Auth (GoTrue).
class AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSource(this._client);

  Future<AuthUser> signUp({required String email, required String password}) async {
    try {
      final response = await _client.auth.signUp(email: email, password: password);
      final user = response.user;
      if (user == null) throw Exception('No pudimos crear tu cuenta.');
      // Without a session the next step (inserting the profile) would be
      // rejected by the row level security policy.
      if (response.session == null) {
        throw Exception('Confirma tu correo y luego ingresa.');
      }
      return AuthUser(id: user.id, email: user.email ?? email);
    } on AuthException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<AuthUser> signIn({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) throw Exception('No pudimos iniciar tu sesión. Inténtalo de nuevo.');
      return AuthUser(id: user.id, email: user.email ?? email);
    } on AuthException catch (e) {
      throw Exception(_message(e));
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(_message(e));
    }
  }

  AuthUser? currentUser() {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AuthUser(id: user.id, email: user.email ?? '');
  }

  String _message(AuthException e) {
    if (e is AuthRetryableFetchException) {
      return 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
    }
    final text = e.message.toLowerCase();
    if (text.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos. Revisa tus datos e inténtalo de nuevo.';
    }
    if (text.contains('already registered')) {
      return 'Ese correo ya está registrado en VIGÍA.';
    }
    return e.message;
  }
}

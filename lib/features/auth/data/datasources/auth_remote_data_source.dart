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
      if (user == null) throw Exception('Could not create the account');
      // Without a session the next step (inserting the profile) would be
      // rejected by the row level security policy.
      if (response.session == null) {
        throw Exception('Please confirm your email address, then log in.');
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
      if (user == null) throw Exception('Could not log in. Please try again.');
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
      return 'Internet connection error. Please check your network connection.';
    }
    final text = e.message.toLowerCase();
    if (text.contains('invalid login credentials')) {
      return 'Invalid credentials. Please verify your email and password.';
    }
    if (text.contains('already registered')) {
      return 'This email is already registered in VIGÍA.';
    }
    return e.message;
  }
}

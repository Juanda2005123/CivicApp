/// What the authentication service returns: who the account is.
///
/// The password never travels through here; it only goes to Auth.
class AuthUser {
  final String id;
  final String email;

  const AuthUser({required this.id, required this.email});
}

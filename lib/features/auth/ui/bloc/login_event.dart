abstract class LoginEvent {}

/// The citizen submitted the login form.
class LoginSubmitted extends LoginEvent {
  final String email;
  final String password;

  LoginSubmitted({required this.email, required this.password});
}

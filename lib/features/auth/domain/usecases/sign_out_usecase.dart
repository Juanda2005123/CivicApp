import 'package:vigia_app/features/notifications/domain/repositories/push_repository.dart';

import '../repositories/auth_repository.dart';

/// Use case: end the active session.
///
/// First this device stops receiving the citizen's push notifications (HU-24),
/// so whoever signs in next on the same phone does not get them. A failure
/// there never blocks signing out.
class SignOutUseCase {
  final AuthRepository _auth;
  final PushRepository? _push;

  SignOutUseCase(this._auth, [this._push]);

  Future<void> call() async {
    final user = _auth.currentUser();
    if (user != null && _push != null) {
      try {
        await _push.disableFor(user.id);
      } on Exception {
        // The topic stays subscribed; the session still ends.
      }
    }
    await _auth.signOut();
  }
}

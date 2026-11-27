import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';

import '../repositories/push_repository.dart';

/// Turns on the pushes of the signed-in citizen (HU-24). A guest has no pushes:
/// nothing happens. A failure (no Google Play, permission denied) never stops
/// the app: the notifications stay in the `notification` table (criterion 4).
class EnablePushUseCase {
  final AuthRepository _auth;
  final PushRepository _push;

  EnablePushUseCase(this._auth, this._push);

  /// Completes with true when this device now receives the citizen's pushes.
  Future<bool> call() async {
    final user = _auth.currentUser();
    if (user == null) return false;
    try {
      await _push.enableFor(user.id);
      return true;
    } on Exception {
      return false;
    }
  }
}

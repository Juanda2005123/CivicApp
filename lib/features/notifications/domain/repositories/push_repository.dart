/// Abstract contract of push notifications (HU-24). Each citizen receives the
/// pushes of their own topic; the server sends one for every new row of the
/// `notification` table.
abstract class PushRepository {
  /// Asks for permission once and subscribes this device to [userId]'s pushes.
  Future<void> enableFor(String userId);

  /// Stops this device from receiving [userId]'s pushes (signing out).
  Future<void> disableFor(String userId);

  /// Ids of the reports the citizen opens by tapping a push, including the one
  /// that launched the app.
  Stream<String> openedReports();
}

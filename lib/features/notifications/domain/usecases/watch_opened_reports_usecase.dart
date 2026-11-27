import '../repositories/push_repository.dart';

/// The reports the citizen opens by tapping a push (HU-24, criterion 3).
class WatchOpenedReportsUseCase {
  final PushRepository _push;

  WatchOpenedReportsUseCase(this._push);

  Stream<String> call() => _push.openedReports().where((id) => id.trim().isNotEmpty);
}

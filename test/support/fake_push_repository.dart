import 'dart:async';

import 'package:vigia_app/features/notifications/domain/repositories/push_repository.dart';

/// In-memory push notifications for the HU-24 tests.
class FakePushRepository implements PushRepository {
  final List<String> calls = [];
  final opened = StreamController<String>.broadcast();
  Exception? enableError;
  Exception? disableError;

  @override
  Future<void> enableFor(String userId) async {
    calls.add('push.enable $userId');
    if (enableError != null) throw enableError!;
  }

  @override
  Future<void> disableFor(String userId) async {
    calls.add('push.disable $userId');
    if (disableError != null) throw disableError!;
  }

  @override
  Stream<String> openedReports() => opened.stream;
}

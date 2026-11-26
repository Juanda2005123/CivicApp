import 'dart:async';

import 'package:vigia_app/features/reports/domain/entities/incident_resolution.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:vigia_app/features/reports/domain/repositories/resolution_repository.dart';

/// In-memory repair proposals for the HU-25 tests. It does not apply the
/// server's quorum; tests that need an outcome set [active] themselves.
class FakeResolutionRepository implements ResolutionRepository {
  final List<String> calls = [];

  /// The pending proposal of each report.
  final Map<String, IncidentResolution> active = {};
  Exception? getError;
  Exception? proposeError;
  Exception? voteError;
  Exception? decideError;

  /// When set, [proposeResolution] waits for it: lets a test see the sending state.
  Completer<void>? proposeGate;

  /// The reporter of each report, so an author's proposal comes back approved.
  final Map<String, String> reporterOf = {};

  PickedPhoto? lastPhoto;
  String? lastDescription;
  String? lastReason;

  @override
  Future<IncidentResolution?> getActiveResolution(String incidentId) async {
    calls.add('resolution.get');
    if (getError != null) throw getError!;
    return active[incidentId];
  }

  @override
  Future<IncidentResolution> proposeResolution({
    required String incidentId,
    required String userId,
    required PickedPhoto photo,
    required String description,
  }) async {
    calls.add('resolution.propose');
    lastPhoto = photo;
    lastDescription = description;
    if (proposeGate != null) await proposeGate!.future;
    if (proposeError != null) throw proposeError!;

    final byAuthor = reporterOf[incidentId] == userId;
    final resolution = IncidentResolution(
      id: 'res-new',
      incidentId: incidentId,
      proponentId: userId,
      photoUrl: 'https://example.com/fixed.jpg',
      description: description,
      status: byAuthor ? ResolutionStatus.approvedByAuthor : ResolutionStatus.pending,
      proposedAt: DateTime.now(),
    );
    if (!byAuthor) active[incidentId] = resolution;
    return resolution;
  }

  @override
  Future<void> confirmResolution({required String resolutionId, required String userId}) async {
    calls.add('resolution.confirm');
    if (voteError != null) throw voteError!;
    _update(resolutionId, (r) => r.withConfirmationBy(userId));
  }

  @override
  Future<void> objectResolution({required String resolutionId, required String userId}) async {
    calls.add('resolution.object');
    if (voteError != null) throw voteError!;
    _update(resolutionId, (r) => r.withObjectionBy(userId));
  }

  @override
  Future<void> acceptResolution(String resolutionId) async {
    calls.add('resolution.accept');
    if (decideError != null) throw decideError!;
    active.removeWhere((_, r) => r.id == resolutionId);
  }

  @override
  Future<void> rejectResolution({required String resolutionId, required String reason}) async {
    calls.add('resolution.reject');
    lastReason = reason;
    if (decideError != null) throw decideError!;
    active.removeWhere((_, r) => r.id == resolutionId);
  }

  void _update(String resolutionId, IncidentResolution Function(IncidentResolution) change) {
    for (final entry in active.entries.toList()) {
      if (entry.value.id == resolutionId) active[entry.key] = change(entry.value);
    }
  }
}

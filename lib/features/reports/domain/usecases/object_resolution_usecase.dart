import '../entities/incident_resolution.dart';
import '../repositories/resolution_repository.dart';
import '../validators/resolution_validators.dart';

/// A neighbor disputes the repair evidence (HU-25, criterion 5). At 3
/// objections the server rejects the proposal and frees the report.
class ObjectResolutionUseCase {
  final ResolutionRepository _repository;

  ObjectResolutionUseCase(this._repository);

  /// [now] is only for tests; it defaults to the device clock.
  Future<void> call({
    required IncidentResolution resolution,
    required String reporterId,
    required String userId,
    DateTime? now,
  }) {
    ResolutionValidators.checkVote(
      resolution: resolution,
      reporterId: reporterId,
      userId: userId.trim(),
      now: now ?? DateTime.now(),
    );
    return _repository.objectResolution(resolutionId: resolution.id, userId: userId.trim());
  }
}

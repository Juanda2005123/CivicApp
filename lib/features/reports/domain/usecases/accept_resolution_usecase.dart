import '../entities/incident_resolution.dart';
import '../repositories/resolution_repository.dart';
import '../validators/resolution_validators.dart';

/// The report author accepts a neighbor's repair proposal (RN-11): the report
/// is resolved and the proponent earns +50 XP on the server.
class AcceptResolutionUseCase {
  final ResolutionRepository _repository;

  AcceptResolutionUseCase(this._repository);

  /// [now] is only for tests; it defaults to the device clock.
  Future<void> call({
    required IncidentResolution resolution,
    required String reporterId,
    required String userId,
    DateTime? now,
  }) {
    ResolutionValidators.checkAuthorDecision(
      resolution: resolution,
      reporterId: reporterId,
      userId: userId.trim(),
      now: now ?? DateTime.now(),
    );
    return _repository.acceptResolution(resolution.id);
  }
}

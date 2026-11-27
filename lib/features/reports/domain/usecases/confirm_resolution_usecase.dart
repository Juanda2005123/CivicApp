import '../entities/incident_resolution.dart';
import '../repositories/resolution_repository.dart';
import '../validators/resolution_validators.dart';

/// A neighbor vouches for the repair (HU-25, criterion 4). At 3 confirmations
/// the server resolves the report and pays +50 XP to the proponent.
class ConfirmResolutionUseCase {
  final ResolutionRepository _repository;

  ConfirmResolutionUseCase(this._repository);

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
    return _repository.confirmResolution(resolutionId: resolution.id, userId: userId.trim());
  }
}

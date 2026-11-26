import '../entities/incident_resolution.dart';
import '../repositories/resolution_repository.dart';
import '../validators/resolution_validators.dart';

/// The report author rejects a neighbor's repair proposal (RN-11) and must say
/// why. The report goes back to its previous status and takes new proposals.
class RejectResolutionUseCase {
  final ResolutionRepository _repository;

  RejectResolutionUseCase(this._repository);

  /// [now] is only for tests; it defaults to the device clock.
  Future<void> call({
    required IncidentResolution resolution,
    required String reporterId,
    required String userId,
    required String reason,
    DateTime? now,
  }) {
    ResolutionValidators.checkAuthorDecision(
      resolution: resolution,
      reporterId: reporterId,
      userId: userId.trim(),
      now: now ?? DateTime.now(),
    );
    final trimmed = reason.trim();
    if (trimmed.length < IncidentResolution.minRejectionReasonLength) {
      throw Exception(
          'Explica por qué rechazas la propuesta (mínimo ${IncidentResolution.minRejectionReasonLength} caracteres).');
    }
    return _repository.rejectResolution(resolutionId: resolution.id, reason: trimmed);
  }
}

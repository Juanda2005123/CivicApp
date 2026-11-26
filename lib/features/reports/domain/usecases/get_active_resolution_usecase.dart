import '../entities/incident_resolution.dart';
import '../repositories/resolution_repository.dart';

/// Reads the pending repair proposal of a report, to pin it on top of the
/// discussion (HU-25). A proposal whose 7 days passed is treated as none: the
/// server marks it expired the next time somebody proposes.
class GetActiveResolutionUseCase {
  final ResolutionRepository _repository;

  GetActiveResolutionUseCase(this._repository);

  /// [now] is only for tests; it defaults to the device clock.
  Future<IncidentResolution?> call(String incidentId, {DateTime? now}) async {
    final resolution = await _repository.getActiveResolution(incidentId.trim());
    if (resolution == null || !resolution.isOpenAt(now ?? DateTime.now())) return null;
    return resolution;
  }
}

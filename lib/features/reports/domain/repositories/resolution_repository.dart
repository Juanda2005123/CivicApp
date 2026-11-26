import '../entities/incident_resolution.dart';
import '../entities/picked_photo.dart';

/// Abstract contract of the community resolution of a report (HU-25, RN-11).
/// The outcome of every action (status of the report, XP, notifications) is
/// the server's job.
abstract class ResolutionRepository {
  /// The pending proposal of a report, or null when there is none.
  Future<IncidentResolution?> getActiveResolution(String incidentId);

  /// Uploads the repair photo and creates the proposal. The author's own
  /// proposal comes back already approved.
  Future<IncidentResolution> proposeResolution({
    required String incidentId,
    required String userId,
    required PickedPhoto photo,
    required String description,
  });

  Future<void> confirmResolution({required String resolutionId, required String userId});

  Future<void> objectResolution({required String resolutionId, required String userId});

  /// The report author accepts a neighbor's proposal.
  Future<void> acceptResolution(String resolutionId);

  /// The report author rejects a neighbor's proposal, saying why.
  Future<void> rejectResolution({required String resolutionId, required String reason});
}

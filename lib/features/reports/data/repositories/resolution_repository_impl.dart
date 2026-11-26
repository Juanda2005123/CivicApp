import '../../domain/entities/incident_resolution.dart';
import '../../domain/entities/picked_photo.dart';
import '../../domain/repositories/resolution_repository.dart';
import '../datasources/resolution_remote_data_source.dart';

/// Fulfils [ResolutionRepository] by delegating to the remote data source.
class ResolutionRepositoryImpl implements ResolutionRepository {
  final ResolutionRemoteDataSource _remote;

  ResolutionRepositoryImpl(this._remote);

  @override
  Future<IncidentResolution?> getActiveResolution(String incidentId) =>
      _remote.getActiveResolution(incidentId);

  @override
  Future<IncidentResolution> proposeResolution({
    required String incidentId,
    required String userId,
    required PickedPhoto photo,
    required String description,
  }) {
    return _remote.proposeResolution(
      incidentId: incidentId,
      userId: userId,
      photo: photo,
      description: description,
    );
  }

  @override
  Future<void> confirmResolution({required String resolutionId, required String userId}) =>
      _remote.confirmResolution(resolutionId: resolutionId, userId: userId);

  @override
  Future<void> objectResolution({required String resolutionId, required String userId}) =>
      _remote.objectResolution(resolutionId: resolutionId, userId: userId);

  @override
  Future<void> acceptResolution(String resolutionId) => _remote.acceptResolution(resolutionId);

  @override
  Future<void> rejectResolution({required String resolutionId, required String reason}) =>
      _remote.rejectResolution(resolutionId: resolutionId, reason: reason);
}

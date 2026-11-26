import '../entities/incident.dart';
import '../entities/incident_resolution.dart';
import '../entities/picked_photo.dart';
import '../repositories/resolution_repository.dart';
import '../validators/report_validators.dart';

/// "Reportar como reparado" (HU-25, criterion 1): one mandatory photo and a
/// description of how the road looks now. Only an open report takes a proposal;
/// the server also refuses a second pending one (criterion 2).
class ProposeResolutionUseCase {
  final ResolutionRepository _repository;

  ProposeResolutionUseCase(this._repository);

  Future<IncidentResolution> call({
    required Incident incident,
    required String userId,
    required PickedPhoto? photo,
    required String description,
  }) {
    if (userId.trim().isEmpty) {
      throw Exception('Debes iniciar sesión para reportar una reparación.');
    }
    if (incident.status == IncidentStatus.resolved) {
      throw Exception('Este reporte ya está resuelto.');
    }
    if (photo == null) {
      throw Exception('Adjunta una foto de la reparación.');
    }
    ReportValidators.validatePhotos([photo]);

    final trimmed = description.trim();
    if (trimmed.length < IncidentResolution.minDescriptionLength) {
      throw Exception(
          'Describe cómo quedó la vía (mínimo ${IncidentResolution.minDescriptionLength} caracteres).');
    }
    if (trimmed.length > IncidentResolution.maxDescriptionLength) {
      throw Exception(
          'La descripción no puede superar los ${IncidentResolution.maxDescriptionLength} caracteres.');
    }

    return _repository.proposeResolution(
      incidentId: incident.id,
      userId: userId.trim(),
      photo: photo,
      description: trimmed,
    );
  }
}

import '../entities/incident.dart';
import '../entities/incident_photo.dart';
import '../entities/picked_photo.dart';
import '../repositories/incident_repository.dart';
import '../validators/report_validators.dart';

/// Applies the author's edit of a report (HU-18, RN-03). It enforces the same
/// validation rules as the first publication (RN-01, RN-02); whether the edit
/// window is still open is decided by the server, not here.
class UpdateIncidentUseCase {
  final IncidentRepository _incidentRepository;

  UpdateIncidentUseCase(this._incidentRepository);

  /// [keptPhotos] are the current photos the author keeps; any other current
  /// photo is removed. [addedPhotos] are the new ones.
  Future<Incident> call({
    required Incident incident,
    required String userId,
    required int categoryId,
    required String title,
    required String description,
    required IncidentSeverity severity,
    String? estimatedDimensions,
    required List<IncidentPhoto> keptPhotos,
    required List<PickedPhoto> addedPhotos,
  }) async {
    if (userId.trim().isEmpty || userId != incident.reporterId) {
      throw Exception('Solo quien publicó el reporte puede modificarlo.');
    }

    ReportValidators.validateTitle(title);
    ReportValidators.validateDescription(description);
    ReportValidators.validatePhotos(addedPhotos);
    if (keptPhotos.length + addedPhotos.length > ReportValidators.maxPhotosAllowed) {
      throw Exception('No puedes adjuntar más de ${ReportValidators.maxPhotosAllowed} fotos por reporte.');
    }

    final keptIds = keptPhotos.map((photo) => photo.id).toSet();
    final removed = incident.photos.where((photo) => !keptIds.contains(photo.id)).toList();
    final dimensions = estimatedDimensions?.trim();

    return _incidentRepository.updateIncident(
      incidentId: incident.id,
      reporterId: userId,
      categoryId: categoryId,
      title: title.trim(),
      description: description.trim(),
      severity: severity,
      estimatedDimensions: (dimensions == null || dimensions.isEmpty) ? null : dimensions,
      removedPhotos: removed,
      addedPhotos: addedPhotos,
    );
  }
}

import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import '../entities/incident.dart';
import '../entities/picked_photo.dart';
import '../repositories/incident_repository.dart';
import '../validators/report_validators.dart';

/// Enforces business validation rules and coordinates report creation and publication (HU-12).
class CreateIncidentUseCase {
  final IncidentRepository _incidentRepository;

  CreateIncidentUseCase(this._incidentRepository);

  Future<Incident> call({
    required String reporterId,
    required int categoryId,
    required String title,
    required String description,
    required IncidentSeverity severity,
    String? estimatedDimensions,
    required Coordinates coordinates,
    required String formattedAddress,
    required String neighborhood,
    required String city,
    required List<PickedPhoto> photos,
  }) async {
    if (reporterId.trim().isEmpty) {
      throw Exception('Debes iniciar sesión para publicar un reporte.');
    }

    ReportValidators.validateTitle(title);
    ReportValidators.validateDescription(description);
    ReportValidators.validateCoordinates(coordinates);
    ReportValidators.validateAddress(formattedAddress);
    ReportValidators.validateNeighborhood(neighborhood);
    ReportValidators.validatePhotos(photos);

    return _incidentRepository.createIncident(
      reporterId: reporterId.trim(),
      categoryId: categoryId,
      title: title.trim(),
      description: description.trim(),
      severity: severity,
      estimatedDimensions: estimatedDimensions?.trim(),
      coordinates: coordinates,
      formattedAddress: formattedAddress.trim(),
      neighborhood: neighborhood.trim(),
      city: city.trim(),
      photos: photos,
    );
  }
}

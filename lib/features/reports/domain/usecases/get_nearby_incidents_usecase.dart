import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import '../entities/nearby_incident.dart';
import '../repositories/incident_repository.dart';
import '../validators/report_validators.dart';

/// Queries for existing reports of the same category near the selected location (HU-08/HU-09).
class GetNearbyIncidentsUseCase {
  final IncidentRepository _incidentRepository;

  GetNearbyIncidentsUseCase(this._incidentRepository);

  Future<List<NearbyIncident>> call({
    required Coordinates coordinates,
    required int categoryId,
    double radiusInMeters = 150.0,
  }) async {
    ReportValidators.validateCoordinates(coordinates);
    return _incidentRepository.getNearbyIncidents(
      coordinates: coordinates,
      categoryId: categoryId,
      radiusInMeters: radiusInMeters,
    );
  }
}

import '../entities/incident.dart';
import '../repositories/incident_repository.dart';

/// Fetches comprehensive incident details by ID or civic tracking code (HU-14).
class GetIncidentByIdUseCase {
  final IncidentRepository _incidentRepository;

  GetIncidentByIdUseCase(this._incidentRepository);

  Future<Incident> call(String idOrTrackingCode) {
    final cleanId = idOrTrackingCode.trim();
    if (cleanId.isEmpty) {
      throw Exception('El identificador del reporte no puede estar vacío.');
    }
    return _incidentRepository.getIncidentById(cleanId);
  }
}

import '../entities/incident.dart';
import '../repositories/incident_repository.dart';

/// Deletes the author's report with its photos (HU-18, RN-03). The server
/// refuses it outside the 30-minute window or with 5 endorsements, and takes
/// back the 100 XP of publishing.
class DeleteIncidentUseCase {
  final IncidentRepository _incidentRepository;

  DeleteIncidentUseCase(this._incidentRepository);

  Future<void> call({required Incident incident, required String userId}) async {
    if (userId.trim().isEmpty || userId != incident.reporterId) {
      throw Exception('Solo quien publicó el reporte puede eliminarlo.');
    }
    return _incidentRepository.deleteIncident(incident);
  }
}

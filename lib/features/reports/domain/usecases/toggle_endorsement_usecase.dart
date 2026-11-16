import '../entities/incident.dart';
import '../repositories/incident_repository.dart';

/// Taps "Apoyar" on a report (HU-15): endorses it, or revokes the endorsement
/// the citizen already gave (RN-04). Nobody endorses their own report (RN-05);
/// the server enforces it too, this gives the citizen a clear message first.
class ToggleEndorsementUseCase {
  final IncidentRepository _incidentRepository;

  ToggleEndorsementUseCase(this._incidentRepository);

  /// Completes with `true` when the report is now endorsed by [userId], `false` when revoked.
  Future<bool> call({required Incident incident, required String userId}) async {
    final id = userId.trim();
    if (id.isEmpty) {
      throw Exception('Debes iniciar sesión para apoyar un reporte.');
    }
    if (incident.reporterId == id) {
      throw Exception('No puedes apoyar tu propio reporte.');
    }

    if (incident.isEndorsedBy(id)) {
      await _incidentRepository.revokeEndorsement(incidentId: incident.id, userId: id);
      return false;
    }
    await _incidentRepository.endorseIncident(incidentId: incident.id, userId: id);
    return true;
  }
}

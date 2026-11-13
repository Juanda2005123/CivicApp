import '../repositories/incident_repository.dart';

/// Endorses (+1 upvote) an existing nearby report when citizen picks "Es este daño" (HU-09/HU-15).
class EndorseIncidentUseCase {
  final IncidentRepository _incidentRepository;

  EndorseIncidentUseCase(this._incidentRepository);

  Future<void> call({
    required String incidentId,
    required String userId,
  }) {
    if (userId.trim().isEmpty) {
      throw Exception('Debes iniciar sesión para apoyar un reporte.');
    }
    if (incidentId.trim().isEmpty) {
      throw Exception('El identificador del reporte es obligatorio.');
    }
    return _incidentRepository.endorseIncident(
      incidentId: incidentId.trim(),
      userId: userId.trim(),
    );
  }
}

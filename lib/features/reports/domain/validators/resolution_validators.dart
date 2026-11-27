import '../entities/incident_resolution.dart';

/// Who may vote on or decide a repair proposal (RN-11). Shared by the
/// resolution use cases; the server checks the same rules again.
class ResolutionValidators {
  const ResolutionValidators._();

  /// A neighbor confirms or objects: an open proposal, neither the proponent
  /// nor the report author, and one vote per person.
  static void checkVote({
    required IncidentResolution resolution,
    required String reporterId,
    required String userId,
    required DateTime now,
  }) {
    if (userId.isEmpty) {
      throw Exception('Debes iniciar sesión para votar la propuesta.');
    }
    if (!resolution.isOpenAt(now)) {
      throw Exception('Esta propuesta ya no está en verificación.');
    }
    if (resolution.proponentId == userId) {
      throw Exception('No puedes votar tu propia propuesta.');
    }
    if (reporterId == userId) {
      throw Exception('Como autor del reporte, acepta o rechaza la propuesta.');
    }
    if (resolution.hasVoted(userId)) {
      throw Exception('Ya votaste esta propuesta.');
    }
  }

  /// Only the report author accepts or rejects, and only an open proposal.
  static void checkAuthorDecision({
    required IncidentResolution resolution,
    required String reporterId,
    required String userId,
    required DateTime now,
  }) {
    if (userId.isEmpty || userId != reporterId) {
      throw Exception('Solo quien publicó el reporte puede aceptar o rechazar la propuesta.');
    }
    if (!resolution.isOpenAt(now)) {
      throw Exception('Esta propuesta ya no está en verificación.');
    }
  }
}

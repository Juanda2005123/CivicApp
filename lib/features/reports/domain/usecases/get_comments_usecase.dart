import '../entities/incident_comment.dart';
import '../repositories/comment_repository.dart';

/// Loads the discussion thread of a report, oldest comment first (HU-17).
class GetCommentsUseCase {
  final CommentRepository _repository;

  GetCommentsUseCase(this._repository);

  Future<List<IncidentComment>> call(String incidentId) {
    if (incidentId.trim().isEmpty) {
      throw Exception('El identificador del reporte es obligatorio.');
    }
    return _repository.getComments(incidentId.trim());
  }
}

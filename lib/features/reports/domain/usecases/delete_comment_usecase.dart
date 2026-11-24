import '../entities/incident_comment.dart';
import '../repositories/comment_repository.dart';

/// Deletes the citizen's own comment during its first 5 minutes (HU-17, RN-06).
/// The server checks the window again with its own clock.
class DeleteCommentUseCase {
  final CommentRepository _repository;

  DeleteCommentUseCase(this._repository);

  /// [now] is only for tests; it defaults to the device clock.
  Future<void> call({
    required IncidentComment comment,
    required String userId,
    DateTime? now,
  }) {
    if (comment.authorId != userId) {
      throw Exception('Solo puedes eliminar tus propios comentarios.');
    }
    if (!comment.canBeDeletedBy(userId, now: now ?? DateTime.now())) {
      throw Exception('Solo puedes eliminar tu comentario durante los primeros 5 minutos.');
    }
    return _repository.deleteComment(comment.id);
  }
}

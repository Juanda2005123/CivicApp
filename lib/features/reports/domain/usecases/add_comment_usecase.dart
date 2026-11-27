import '../entities/incident_comment.dart';
import '../entities/picked_photo.dart';
import '../repositories/comment_repository.dart';
import '../validators/report_validators.dart';

/// Publishes a comment (HU-17). It needs text, a photo or both (RN-06), the text
/// has a limit, and the photo is a single JPG, PNG or WebP image of at most 5 MB.
class AddCommentUseCase {
  final CommentRepository _repository;

  AddCommentUseCase(this._repository);

  Future<IncidentComment> call({
    required String incidentId,
    required String userId,
    required String text,
    PickedPhoto? photo,
  }) {
    if (userId.trim().isEmpty) {
      throw Exception('Debes iniciar sesión para comentar.');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty && photo == null) {
      throw Exception('Escribe un comentario o adjunta una foto.');
    }
    if (trimmed.length > IncidentComment.maxTextLength) {
      throw Exception('El comentario no puede superar los ${IncidentComment.maxTextLength} caracteres.');
    }
    if (photo != null) {
      ReportValidators.validatePhotos([photo]);
    }

    return _repository.addComment(
      incidentId: incidentId.trim(),
      userId: userId.trim(),
      text: trimmed,
      photo: photo,
    );
  }
}

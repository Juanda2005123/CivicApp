import '../entities/incident_comment.dart';
import '../entities/picked_photo.dart';

/// Abstract contract of the discussion thread of a report (HU-17).
abstract class CommentRepository {
  /// Comments of a report, oldest first.
  Future<List<IncidentComment>> getComments(String incidentId);

  /// Publishes a comment with an optional photo. XP and notifications are the
  /// server's job. When the photo cannot be saved the comment is not left behind.
  Future<IncidentComment> addComment({
    required String incidentId,
    required String userId,
    required String text,
    PickedPhoto? photo,
  });

  /// Deletes a comment (text and photo). The server refuses it after the window.
  Future<void> deleteComment(String commentId);
}

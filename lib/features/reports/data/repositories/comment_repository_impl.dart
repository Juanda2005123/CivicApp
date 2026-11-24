import '../../domain/entities/incident_comment.dart';
import '../../domain/entities/picked_photo.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/comment_remote_data_source.dart';

/// Fulfils [CommentRepository] by delegating to the remote data source.
class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource _remote;

  CommentRepositoryImpl(this._remote);

  @override
  Future<List<IncidentComment>> getComments(String incidentId) => _remote.getComments(incidentId);

  @override
  Future<IncidentComment> addComment({
    required String incidentId,
    required String userId,
    required String text,
    PickedPhoto? photo,
  }) {
    return _remote.addComment(incidentId: incidentId, userId: userId, text: text, photo: photo);
  }

  @override
  Future<void> deleteComment(String commentId) => _remote.deleteComment(commentId);
}

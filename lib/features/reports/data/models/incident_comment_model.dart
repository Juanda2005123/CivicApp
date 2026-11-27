import '../../domain/entities/incident_comment.dart';

/// DTO mapping a row of `incident_comment` (joined with its author and photo) to
/// the [IncidentComment] entity.
class IncidentCommentModel extends IncidentComment {
  const IncidentCommentModel({
    required super.id,
    required super.incidentId,
    required super.authorId,
    super.authorName,
    super.authorRankLevel,
    super.authorRankName,
    super.authorAvatarUrl,
    super.text,
    super.photoUrl,
    required super.createdAt,
  });

  factory IncidentCommentModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final rank = author?['civic_rank'] as Map<String, dynamic>?;

    return IncidentCommentModel(
      id: json['id_comment'] as String,
      incidentId: json['id_incident'] as String,
      authorId: json['id_user'] as String,
      authorName: (author == null || author['show_real_name'] == false)
          ? null
          : author['full_name'] as String?,
      authorRankLevel: ((author?['id_rank'] as num?)?.toInt() ?? 1).clamp(1, 4),
      authorRankName: rank?['name'] as String?,
      authorAvatarUrl: author?['profile_picture_url'] as String?,
      text: (json['content'] as String?) ?? '',
      photoUrl: _photoUrl(json['comment_photo']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// The photo is one-to-one with the comment: PostgREST answers an object, a
  /// list or null depending on how the relation is read.
  static String? _photoUrl(Object? photo) {
    if (photo is Map<String, dynamic>) return photo['file_url'] as String?;
    if (photo is List && photo.isNotEmpty) {
      return (photo.first as Map<String, dynamic>)['file_url'] as String?;
    }
    return null;
  }
}

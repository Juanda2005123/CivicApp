import 'package:equatable/equatable.dart';

/// A comment in the discussion thread of a report (HU-17). Comments never change
/// after they are published (RN-06): the author may only delete them, and only
/// during the first [deletionWindow].
class IncidentComment extends Equatable {
  /// How long the author can delete their comment (RN-06). The server enforces it too.
  static const Duration deletionWindow = Duration(minutes: 5);

  /// Longest text a comment may have; the database refuses more.
  static const int maxTextLength = 500;

  final String id;
  final String incidentId;
  final String authorId;
  final String? authorName;

  /// Civic rank level of the author, 1 to 4 (RN-09).
  final int authorRankLevel;
  final String? authorRankName;
  final String? authorAvatarUrl;

  /// Empty when the comment is only a photo (RN-06).
  final String text;
  final String? photoUrl;
  final DateTime createdAt;

  const IncidentComment({
    required this.id,
    required this.incidentId,
    required this.authorId,
    this.authorName,
    this.authorRankLevel = 1,
    this.authorRankName,
    this.authorAvatarUrl,
    this.text = '',
    this.photoUrl,
    required this.createdAt,
  });

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  bool get hasText => text.trim().isNotEmpty;

  /// Last instant at which the author can still delete the comment.
  DateTime get deletableUntil => createdAt.add(deletionWindow);

  /// Whether [userId] can delete this comment at [now]: only the author, only
  /// inside the window.
  bool canBeDeletedBy(String userId, {required DateTime now}) =>
      authorId == userId && now.isBefore(deletableUntil);

  @override
  List<Object?> get props => [
        id,
        incidentId,
        authorId,
        authorName,
        authorRankLevel,
        authorRankName,
        authorAvatarUrl,
        text,
        photoUrl,
        createdAt,
      ];
}

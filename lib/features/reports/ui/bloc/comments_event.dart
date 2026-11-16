import 'package:equatable/equatable.dart';

import '../../domain/entities/incident_comment.dart';

abstract class CommentsEvent extends Equatable {
  const CommentsEvent();

  @override
  List<Object?> get props => [];
}

/// The thread of a report opens (or is reloaded after a failure).
class CommentsStarted extends CommentsEvent {
  final String incidentId;

  const CommentsStarted(this.incidentId);

  @override
  List<Object?> get props => [incidentId];
}

/// The citizen chose to attach a photo, from the camera or the gallery.
class CommentPhotoRequested extends CommentsEvent {
  final bool fromCamera;

  const CommentPhotoRequested({this.fromCamera = false});

  @override
  List<Object?> get props => [fromCamera];
}

/// The citizen took the attached photo off the comment they are writing.
class CommentPhotoRemoved extends CommentsEvent {
  const CommentPhotoRemoved();
}

/// The citizen tapped "Publicar" with this text (may be empty if a photo is attached).
class CommentSubmitted extends CommentsEvent {
  final String text;

  const CommentSubmitted(this.text);

  @override
  List<Object?> get props => [text];
}

/// The citizen confirmed deleting their own comment.
class CommentDeleted extends CommentsEvent {
  final IncidentComment comment;

  const CommentDeleted(this.comment);

  @override
  List<Object?> get props => [comment];
}

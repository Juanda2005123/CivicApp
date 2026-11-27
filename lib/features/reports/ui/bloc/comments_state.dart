import 'package:equatable/equatable.dart';

import '../../domain/entities/incident_comment.dart';
import '../../domain/entities/picked_photo.dart';

enum CommentsStatus { initial, loading, success, failure }

/// State of the discussion thread of a report (HU-17).
class CommentsState extends Equatable {
  final CommentsStatus status;
  final String? incidentId;

  /// Oldest first, as the thread reads.
  final List<IncidentComment> comments;

  /// Id of the signed-in citizen, or null for a guest (HU-22): a guest reads the
  /// thread but the composer asks them to sign in.
  final String? viewerId;

  /// Photo attached to the comment being written.
  final PickedPhoto? draftPhoto;

  /// A comment is on its way: the button shows it and ignores taps.
  final bool isSending;

  /// Id of the comment being deleted, if any.
  final String? deletingId;

  /// Why the thread could not load.
  final String? errorMessage;

  /// Why the last action (pick, publish or delete) failed. The screen shows it
  /// once; the text and photo the citizen wrote are kept (HU-17, criterion 7).
  final String? actionError;

  /// Grows by one every time a comment is published: the screen clears its text
  /// field when it changes.
  final int publishedCount;

  const CommentsState({
    this.status = CommentsStatus.initial,
    this.incidentId,
    this.comments = const [],
    this.viewerId,
    this.draftPhoto,
    this.isSending = false,
    this.deletingId,
    this.errorMessage,
    this.actionError,
    this.publishedCount = 0,
  });

  bool get isGuest => viewerId == null;

  CommentsState copyWith({
    CommentsStatus? status,
    String? incidentId,
    List<IncidentComment>? comments,
    String? viewerId,
    PickedPhoto? draftPhoto,
    bool removeDraftPhoto = false,
    bool? isSending,
    String? deletingId,
    bool clearDeletingId = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionError,
    bool clearActionError = false,
    int? publishedCount,
  }) {
    return CommentsState(
      status: status ?? this.status,
      incidentId: incidentId ?? this.incidentId,
      comments: comments ?? this.comments,
      viewerId: viewerId ?? this.viewerId,
      draftPhoto: removeDraftPhoto ? null : (draftPhoto ?? this.draftPhoto),
      isSending: isSending ?? this.isSending,
      deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      publishedCount: publishedCount ?? this.publishedCount,
    );
  }

  @override
  List<Object?> get props => [
        status,
        incidentId,
        comments,
        viewerId,
        draftPhoto,
        isSending,
        deletingId,
        errorMessage,
        actionError,
        publishedCount,
      ];
}

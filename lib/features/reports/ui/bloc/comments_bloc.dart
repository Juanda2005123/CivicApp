import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/usecases/get_current_profile_usecase.dart';
import '../../domain/usecases/add_comment_usecase.dart';
import '../../domain/usecases/delete_comment_usecase.dart';
import '../../domain/usecases/get_comments_usecase.dart';
import '../../domain/usecases/pick_comment_photo_usecase.dart';
import 'comments_event.dart';
import 'comments_state.dart';

/// Discussion thread of a report: loads it, publishes and deletes comments (HU-17).
class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final GetCommentsUseCase _getComments;
  final AddCommentUseCase _addComment;
  final DeleteCommentUseCase _deleteComment;
  final PickCommentPhotoUseCase _pickPhoto;
  final GetCurrentProfileUseCase _getCurrentProfile;

  CommentsBloc(
    this._getComments,
    this._addComment,
    this._deleteComment,
    this._pickPhoto,
    this._getCurrentProfile,
  ) : super(const CommentsState()) {
    on<CommentsStarted>(_onStarted);
    on<CommentPhotoRequested>(_onPhotoRequested);
    on<CommentPhotoRemoved>(_onPhotoRemoved);
    on<CommentSubmitted>(_onSubmitted);
    on<CommentDeleted>(_onDeleted);
  }

  Future<void> _onStarted(CommentsStarted event, Emitter<CommentsState> emit) async {
    emit(state.copyWith(
      status: CommentsStatus.loading,
      incidentId: event.incidentId,
      clearErrorMessage: true,
    ));
    try {
      final viewerId = await _viewerId();
      final comments = await _getComments(event.incidentId);
      emit(state.copyWith(status: CommentsStatus.success, comments: comments, viewerId: viewerId));
    } on Exception catch (e) {
      emit(state.copyWith(status: CommentsStatus.failure, errorMessage: _message(e)));
    }
  }

  /// A photo that is too big or in the wrong format is refused here, with the
  /// reason, and the one already attached stays (HU-17, criterion 4).
  Future<void> _onPhotoRequested(CommentPhotoRequested event, Emitter<CommentsState> emit) async {
    if (state.isSending) return;
    try {
      final photo = await _pickPhoto(fromCamera: event.fromCamera);
      if (photo == null) return;
      emit(state.copyWith(draftPhoto: photo, clearActionError: true));
    } on Exception catch (e) {
      emit(state.copyWith(actionError: _message(e)));
    }
  }

  void _onPhotoRemoved(CommentPhotoRemoved event, Emitter<CommentsState> emit) {
    if (state.isSending) return;
    emit(state.copyWith(removeDraftPhoto: true));
  }

  /// On success the comment joins the end of the thread and the photo is cleared;
  /// on failure the draft stays as it was and the reason is reported.
  Future<void> _onSubmitted(CommentSubmitted event, Emitter<CommentsState> emit) async {
    final incidentId = state.incidentId;
    final viewerId = state.viewerId;
    if (incidentId == null || viewerId == null || state.isSending) return;

    emit(state.copyWith(isSending: true, clearActionError: true));
    try {
      final comment = await _addComment(
        incidentId: incidentId,
        userId: viewerId,
        text: event.text,
        photo: state.draftPhoto,
      );
      emit(state.copyWith(
        comments: [...state.comments, comment],
        isSending: false,
        removeDraftPhoto: true,
        publishedCount: state.publishedCount + 1,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(isSending: false, actionError: _message(e)));
    }
  }

  Future<void> _onDeleted(CommentDeleted event, Emitter<CommentsState> emit) async {
    final viewerId = state.viewerId;
    if (viewerId == null || state.deletingId != null) return;

    emit(state.copyWith(deletingId: event.comment.id, clearActionError: true));
    try {
      await _deleteComment(comment: event.comment, userId: viewerId);
      emit(state.copyWith(
        comments: state.comments.where((c) => c.id != event.comment.id).toList(),
        clearDeletingId: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(clearDeletingId: true, actionError: _message(e)));
    }
  }

  /// The signed-in citizen's id, or null for a guest or when the profile cannot be read.
  Future<String?> _viewerId() async {
    try {
      return (await _getCurrentProfile())?.id;
    } on Exception {
      return null;
    }
  }

  String _message(Exception e) => e.toString().replaceFirst('Exception: ', '').trim();
}

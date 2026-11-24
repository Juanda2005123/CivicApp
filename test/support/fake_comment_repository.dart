import 'dart:async';

import 'package:vigia_app/features/reports/domain/entities/incident_comment.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:vigia_app/features/reports/domain/repositories/comment_repository.dart';

/// In-memory thread of comments for the HU-17 tests.
class FakeCommentRepository implements CommentRepository {
  final List<String> calls = [];
  final Map<String, List<IncidentComment>> byIncident = {};
  Exception? getError;
  Exception? addError;
  Exception? deleteError;

  /// When set, [addComment] waits for it: lets a test see the sending state.
  Completer<void>? addGate;

  /// What the fake stamps on a new comment as its publishing time.
  DateTime Function() clock = DateTime.now;

  /// The photo and text of the last [addComment] call.
  PickedPhoto? lastPhoto;
  String? lastText;

  @override
  Future<List<IncidentComment>> getComments(String incidentId) async {
    calls.add('comment.get');
    if (getError != null) throw getError!;
    return List.of(byIncident[incidentId] ?? const []);
  }

  @override
  Future<IncidentComment> addComment({
    required String incidentId,
    required String userId,
    required String text,
    PickedPhoto? photo,
  }) async {
    calls.add('comment.add');
    lastPhoto = photo;
    lastText = text;
    if (addGate != null) await addGate!.future;
    if (addError != null) throw addError!;

    final thread = byIncident.putIfAbsent(incidentId, () => []);
    final comment = IncidentComment(
      id: 'c-${thread.length + 1}',
      incidentId: incidentId,
      authorId: userId,
      authorName: 'Vecino Uno',
      text: text,
      photoUrl: photo == null ? null : 'https://example.com/comment.jpg',
      createdAt: clock(),
    );
    thread.add(comment);
    return comment;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    calls.add('comment.delete');
    if (deleteError != null) throw deleteError!;
    for (final thread in byIncident.values) {
      thread.removeWhere((c) => c.id == commentId);
    }
  }
}

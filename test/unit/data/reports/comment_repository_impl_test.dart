import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/data/datasources/comment_remote_data_source.dart';
import 'package:vigia_app/features/reports/data/models/incident_comment_model.dart';
import 'package:vigia_app/features/reports/data/repositories/comment_repository_impl.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';

import '../../../support/comment_samples.dart';

class _FakeCommentRemoteDataSource implements CommentRemoteDataSource {
  final List<String> calls = [];
  String? lastText;
  PickedPhoto? lastPhoto;

  @override
  Future<List<IncidentCommentModel>> getComments(String incidentId) async {
    calls.add('remote.getComments');
    return const [];
  }

  @override
  Future<IncidentCommentModel> addComment({
    required String incidentId,
    required String userId,
    required String text,
    PickedPhoto? photo,
  }) async {
    calls.add('remote.addComment');
    lastText = text;
    lastPhoto = photo;
    return IncidentCommentModel(
      id: 'c-1',
      incidentId: incidentId,
      authorId: userId,
      text: text,
      createdAt: DateTime(2026, 11, 16),
    );
  }

  @override
  Future<void> deleteComment(String commentId) async {
    calls.add('remote.deleteComment');
  }
}

void main() {
  group('CommentRepositoryImpl delegates to the remote data source', () {
    late _FakeCommentRemoteDataSource remote;
    late CommentRepositoryImpl repository;

    setUp(() {
      remote = _FakeCommentRemoteDataSource();
      repository = CommentRepositoryImpl(remote);
    });

    test('getComments', () async {
      await repository.getComments('inc-1');

      expect(remote.calls, ['remote.getComments']);
    });

    test('addComment passes the text and the photo along', () async {
      final photo = samplePhoto();

      final comment = await repository.addComment(incidentId: 'inc-1', userId: 'me', text: 'Hola', photo: photo);

      expect(remote.calls, ['remote.addComment']);
      expect(remote.lastText, 'Hola');
      expect(remote.lastPhoto, photo);
      expect(comment.authorId, 'me');
    });

    test('deleteComment', () async {
      await repository.deleteComment('c-1');

      expect(remote.calls, ['remote.deleteComment']);
    });
  });
}

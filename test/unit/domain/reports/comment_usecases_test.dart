import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_comment.dart';
import 'package:vigia_app/features/reports/domain/usecases/add_comment_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/delete_comment_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_comments_usecase.dart';

import '../../../support/comment_samples.dart';
import '../../../support/fake_comment_repository.dart';

Matcher failsWith(String text) => throwsA(predicate((e) => e.toString().contains(text)));

void main() {
  late FakeCommentRepository repository;

  setUp(() {
    repository = FakeCommentRepository();
  });

  group('GetCommentsUseCase', () {
    test('returns the thread of the report', () async {
      repository.byIncident['inc-1'] = [sampleComment(id: 'c-1'), sampleComment(id: 'c-2')];

      final comments = await GetCommentsUseCase(repository)('inc-1');

      expect(comments.map((c) => c.id), ['c-1', 'c-2']);
    });

    test('refuses an empty report id', () {
      expect(() => GetCommentsUseCase(repository)('  '), failsWith('identificador'));
    });
  });

  group('AddCommentUseCase', () {
    late AddCommentUseCase add;

    setUp(() {
      add = AddCommentUseCase(repository);
    });

    test('publishes a text comment trimmed', () async {
      final comment = await add(incidentId: 'inc-1', userId: 'me', text: '  Hola vecinos  ');

      expect(comment.text, 'Hola vecinos');
      expect(repository.calls, ['comment.add']);
    });

    test('a photo alone is a valid comment (RN-06)', () async {
      final comment = await add(incidentId: 'inc-1', userId: 'me', text: '   ', photo: samplePhoto());

      expect(comment.text, isEmpty);
      expect(comment.hasPhoto, isTrue);
    });

    test('refuses a comment with neither text nor photo', () {
      expect(() => add(incidentId: 'inc-1', userId: 'me', text: '   '), failsWith('Escribe un comentario'));
      expect(repository.calls, isEmpty);
    });

    test('refuses a text over the limit and accepts exactly the limit', () async {
      expect(
        () => add(incidentId: 'inc-1', userId: 'me', text: 'x' * (IncidentComment.maxTextLength + 1)),
        failsWith('500 caracteres'),
      );

      final comment = await add(incidentId: 'inc-1', userId: 'me', text: 'x' * IncidentComment.maxTextLength);
      expect(comment.text.length, IncidentComment.maxTextLength);
    });

    test('refuses a photo over 5 MB or in a format that is not JPG, PNG or WebP', () {
      expect(
        () => add(incidentId: 'inc-1', userId: 'me', text: 'Mira', photo: samplePhoto(sizeInBytes: 6 * 1024 * 1024)),
        failsWith('5 MB'),
      );
      expect(
        () => add(incidentId: 'inc-1', userId: 'me', text: 'Mira', photo: samplePhoto(extension: 'gif')),
        failsWith('JPG, PNG o WebP'),
      );
      expect(repository.calls, isEmpty);
    });

    test('accepts the three allowed formats', () async {
      for (final extension in ['jpg', 'png', 'webp']) {
        await add(incidentId: 'inc-1', userId: 'me', text: '', photo: samplePhoto(extension: extension));
      }

      expect(repository.calls, hasLength(3));
    });

    test('a guest cannot comment', () {
      expect(() => add(incidentId: 'inc-1', userId: ' ', text: 'Hola'), failsWith('iniciar sesión'));
    });
  });

  group('DeleteCommentUseCase', () {
    late DeleteCommentUseCase delete;
    final published = DateTime(2026, 11, 16, 10);

    setUp(() {
      delete = DeleteCommentUseCase(repository);
    });

    test('deletes the own comment inside the window', () async {
      await delete(
        comment: sampleComment(createdAt: published),
        userId: 'me',
        now: published.add(const Duration(minutes: 2)),
      );

      expect(repository.calls, ['comment.delete']);
    });

    test('refuses after 5 minutes without calling the repository', () {
      expect(
        () => delete(
          comment: sampleComment(createdAt: published),
          userId: 'me',
          now: published.add(const Duration(minutes: 6)),
        ),
        failsWith('primeros 5 minutos'),
      );
      expect(repository.calls, isEmpty);
    });

    test('refuses a comment of someone else', () {
      expect(
        () => delete(comment: sampleComment(authorId: 'other', createdAt: published), userId: 'me', now: published),
        failsWith('propios comentarios'),
      );
      expect(repository.calls, isEmpty);
    });
  });
}

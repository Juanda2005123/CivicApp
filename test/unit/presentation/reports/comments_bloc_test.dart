import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/ui/bloc/comments_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/comments_event.dart';
import 'package:vigia_app/features/reports/ui/bloc/comments_state.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/comment_samples.dart';
import '../../../support/detail_bloc_factory.dart';
import '../../../support/fake_comment_repository.dart';
import '../../../support/fakes.dart';

void main() {
  group('CommentsBloc (HU-17)', () {
    late FakeCommentRepository repository;
    late FakePhotoPickerRepository picker;
    late CommentsBloc bloc;

    setUp(() {
      repository = FakeCommentRepository();
      picker = FakePhotoPickerRepository();
      bloc = buildCommentsBloc(repository, picker: picker);
    });

    tearDown(() => bloc.close());

    /// Opens the thread of report `inc-1` and waits until it is on screen.
    Future<void> openThread() async {
      bloc.add(const CommentsStarted('inc-1'));
      await pumpEventQueue();
    }

    group('CommentsStarted', () {
      test('loads the thread oldest first, for the signed-in citizen', () async {
        repository.byIncident['inc-1'] = [sampleComment(id: 'c-1'), sampleComment(id: 'c-2')];

        final states = await emittedStates(bloc, const CommentsStarted('inc-1'));

        expect(states.map((s) => s.status), [CommentsStatus.loading, CommentsStatus.success]);
        expect(states.last.comments.map((c) => c.id), ['c-1', 'c-2']);
        expect(states.last.viewerId, 'me');
        expect(states.last.isGuest, isFalse);
      });

      test('a guest reads the thread without a viewer id', () async {
        bloc = buildCommentsBloc(repository, guest: true);
        repository.byIncident['inc-1'] = [sampleComment()];

        final states = await emittedStates(bloc, const CommentsStarted('inc-1'));

        expect(states.last.status, CommentsStatus.success);
        expect(states.last.isGuest, isTrue);
        expect(states.last.comments, hasLength(1));
      });

      test('a failed load reports why and can be retried', () async {
        repository.getError = Exception('Sin conexión');

        final failed = await emittedStates(bloc, const CommentsStarted('inc-1'));
        expect(failed.last.status, CommentsStatus.failure);
        expect(failed.last.errorMessage, 'Sin conexión');

        repository.getError = null;
        final retried = await emittedStates(bloc, const CommentsStarted('inc-1'));
        expect(retried.last.status, CommentsStatus.success);
        expect(retried.last.errorMessage, isNull);
      });
    });

    group('CommentSubmitted', () {
      test('publishes at the end of the thread and counts it', () async {
        repository.byIncident['inc-1'] = [sampleComment(id: 'c-1', authorId: 'other')];
        await openThread();

        final states = await emittedStates(bloc, const CommentSubmitted('Gracias por avisar'));

        expect(states.first.isSending, isTrue);
        expect(states.last.isSending, isFalse);
        expect(states.last.comments.map((c) => c.text), ['Sigue igual de mal.', 'Gracias por avisar']);
        expect(states.last.comments.last.authorId, 'me');
        expect(states.last.publishedCount, 1);
        expect(states.last.actionError, isNull);
      });

      test('a photo alone is published and the attached photo is cleared', () async {
        picker.photoToReturn = samplePhoto();
        await openThread();
        bloc.add(const CommentPhotoRequested());
        await pumpEventQueue();
        expect(bloc.state.draftPhoto, isNotNull);

        final states = await emittedStates(bloc, const CommentSubmitted(''));

        expect(states.last.comments.single.hasPhoto, isTrue);
        expect(states.last.comments.single.hasText, isFalse);
        expect(states.last.draftPhoto, isNull);
        expect(repository.lastPhoto, isNotNull);
      });

      test('a failure keeps the attached photo and tells why (criterion 7)', () async {
        picker.photoToReturn = samplePhoto();
        await openThread();
        bloc.add(const CommentPhotoRequested());
        await pumpEventQueue();
        repository.addError = Exception('Sin conexión');

        final states = await emittedStates(bloc, const CommentSubmitted('Hola'));

        expect(states.last.isSending, isFalse);
        expect(states.last.actionError, 'Sin conexión');
        expect(states.last.draftPhoto, isNotNull);
        expect(states.last.comments, isEmpty);
        expect(states.last.publishedCount, 0);
      });

      test('nothing to say is refused with a clear message', () async {
        await openThread();

        final states = await emittedStates(bloc, const CommentSubmitted('   '));

        expect(states.last.actionError, 'Escribe un comentario o adjunta una foto.');
        expect(repository.calls, isNot(contains('comment.add')));
      });

      test('a guest cannot publish', () async {
        bloc = buildCommentsBloc(repository, guest: true);
        await openThread();
        repository.calls.clear();

        final states = await emittedStates(bloc, const CommentSubmitted('Hola'));

        expect(states, isEmpty);
        expect(repository.calls, isEmpty);
      });

      test('a second tap while sending is ignored', () async {
        await openThread();
        repository.addGate = Completer<void>();

        bloc.add(const CommentSubmitted('Uno'));
        await pumpEventQueue();
        bloc.add(const CommentSubmitted('Dos'));
        await pumpEventQueue();
        repository.addGate!.complete();
        await pumpEventQueue();

        expect(repository.calls.where((c) => c == 'comment.add'), hasLength(1));
        expect(bloc.state.comments, hasLength(1));
      });
    });

    group('CommentPhotoRequested', () {
      setUp(() async {
        await openThread();
      });

      test('attaches the picked photo', () async {
        picker.photoToReturn = samplePhoto();

        final states = await emittedStates(bloc, const CommentPhotoRequested());

        expect(states.last.draftPhoto, isNotNull);
      });

      test('cancelling changes nothing', () async {
        picker.photoToReturn = null;

        final states = await emittedStates(bloc, const CommentPhotoRequested());

        expect(states, isEmpty);
      });

      test('a photo over 5 MB is refused and the attached one stays (criterion 4)', () async {
        picker.photoToReturn = samplePhoto();
        bloc.add(const CommentPhotoRequested());
        await pumpEventQueue();
        final attached = bloc.state.draftPhoto;

        picker.photoToReturn = samplePhoto(sizeInBytes: 6 * 1024 * 1024);
        final states = await emittedStates(bloc, const CommentPhotoRequested());

        expect(states.last.actionError, contains('5 MB'));
        expect(states.last.draftPhoto, attached);
      });

      test('a format that is not JPG, PNG or WebP is refused', () async {
        picker.photoToReturn = samplePhoto(extension: 'gif');

        final states = await emittedStates(bloc, const CommentPhotoRequested());

        expect(states.last.actionError, contains('JPG, PNG o WebP'));
        expect(states.last.draftPhoto, isNull);
      });

      test('the attached photo can be removed', () async {
        picker.photoToReturn = samplePhoto();
        bloc.add(const CommentPhotoRequested());
        await pumpEventQueue();

        final states = await emittedStates(bloc, const CommentPhotoRemoved());

        expect(states.last.draftPhoto, isNull);
      });
    });

    group('CommentDeleted', () {
      test('removes the own recent comment', () async {
        final mine = sampleComment(id: 'c-1', createdAt: DateTime.now());
        repository.byIncident['inc-1'] = [mine, sampleComment(id: 'c-2', authorId: 'other')];
        await openThread();

        final states = await emittedStates(bloc, CommentDeleted(mine));

        expect(states.first.deletingId, 'c-1');
        expect(states.last.deletingId, isNull);
        expect(states.last.comments.map((c) => c.id), ['c-2']);
        expect(repository.calls, contains('comment.delete'));
      });

      test('after 5 minutes it is refused and the comment stays', () async {
        final old = sampleComment(id: 'c-1', createdAt: DateTime.now().subtract(const Duration(minutes: 6)));
        repository.byIncident['inc-1'] = [old];
        await openThread();
        repository.calls.clear();

        final states = await emittedStates(bloc, CommentDeleted(old));

        expect(states.last.actionError, 'Solo puedes eliminar tu comentario durante los primeros 5 minutos.');
        expect(states.last.comments, hasLength(1));
        expect(repository.calls, isEmpty);
      });

      test('a failed request keeps the comment and tells why', () async {
        final mine = sampleComment(createdAt: DateTime.now());
        repository.byIncident['inc-1'] = [mine];
        await openThread();
        repository.deleteError = Exception('Sin conexión');

        final states = await emittedStates(bloc, CommentDeleted(mine));

        expect(states.last.actionError, 'Sin conexión');
        expect(states.last.comments, hasLength(1));
        expect(states.last.deletingId, isNull);
      });
    });
  });
}

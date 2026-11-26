import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_resolution.dart';
import 'package:vigia_app/features/reports/ui/bloc/resolution_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/resolution_event.dart';
import 'package:vigia_app/features/reports/ui/bloc/resolution_state.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/comment_samples.dart';
import '../../../support/detail_bloc_factory.dart';
import '../../../support/fake_resolution_repository.dart';
import '../../../support/fakes.dart';
import '../../../support/incident_samples.dart';
import '../../../support/resolution_samples.dart';

void main() {
  late FakeResolutionRepository repository;
  late ResolutionBloc bloc;
  final incident = sampleIncident();

  /// A proposal made right now, so it is still open.
  IncidentResolution openProposal({List<String> confirmerIds = const []}) =>
      sampleResolution(proposedAt: DateTime.now(), confirmerIds: confirmerIds);

  Future<void> open(ResolutionBloc target, [Incident? report]) async {
    target.add(ResolutionStarted(report ?? incident));
    await pumpEventQueue();
  }

  setUp(() {
    repository = FakeResolutionRepository()..reporterOf['inc-1'] = 'author-1';
    bloc = buildResolutionBloc(
      repository,
      picker: FakePhotoPickerRepository(photoToReturn: samplePhoto()),
    );
  });

  tearDown(() => bloc.close());

  group('ResolutionStarted', () {
    test('loads the pending proposal and who is looking', () async {
      repository.active['inc-1'] = openProposal();

      final states = await emittedStates(bloc, ResolutionStarted(incident));

      expect(states.first.status, ResolutionLoadStatus.loading);
      expect(states.last.status, ResolutionLoadStatus.success);
      expect(states.last.resolution?.id, 'res-1');
      expect(states.last.viewerId, 'me');
      expect(states.last.canPropose, isFalse);
    });

    test('with no proposal an open report can be proposed (criterion 1)', () async {
      await open(bloc);

      expect(bloc.state.resolution, isNull);
      expect(bloc.state.canPropose, isTrue);
    });

    test('a resolved report takes no proposal', () async {
      await open(bloc, sampleIncident(status: IncidentStatus.resolved));

      expect(bloc.state.canPropose, isFalse);
    });

    test('a failure is reported', () async {
      repository.getError = Exception('Sin conexión');

      await open(bloc);

      expect(bloc.state.status, ResolutionLoadStatus.failure);
      expect(bloc.state.errorMessage, 'Sin conexión');
    });
  });

  group('ResolutionProposalSubmitted', () {
    setUp(() async {
      await open(bloc);
      bloc.add(const ResolutionPhotoRequested(fromCamera: true));
      await pumpEventQueue();
    });

    test('a neighbor\'s proposal is pinned for verification and the report reloads', () async {
      final states = await emittedStates(bloc, const ResolutionProposalSubmitted('Ya taparon el hueco.'));

      expect(states.first.isSubmitting, isTrue);
      final last = states.last;
      expect(last.isSubmitting, isFalse);
      expect(last.resolution?.status, ResolutionStatus.pending);
      expect(last.draftPhoto, isNull);
      expect(last.submittedCount, 1);
      expect(last.reportChangedCount, 1);
      expect(last.notice, contains('en verificación'));
      expect(repository.lastPhoto, isNotNull);
    });

    test('the author\'s own proposal closes the report at once (criterion 3)', () async {
      final authorBloc = buildResolutionBloc(
        repository,
        viewerId: 'author-1',
        picker: FakePhotoPickerRepository(photoToReturn: samplePhoto()),
      );
      addTearDown(authorBloc.close);
      await open(authorBloc);
      authorBloc.add(const ResolutionPhotoRequested());
      await pumpEventQueue();

      final states = await emittedStates(authorBloc, const ResolutionProposalSubmitted('Ya taparon el hueco.'));

      expect(states.last.resolution, isNull);
      expect(states.last.notice, contains('cerraste el reporte'));
      expect(states.last.reportChangedCount, 1);
    });

    test('a second proposal shows the active one to vote on instead (criterion 2)', () async {
      repository.proposeError = Exception('Ya hay una propuesta de reparación en verificación para este reporte.');
      repository.active['inc-1'] = openProposal();

      final states = await emittedStates(bloc, const ResolutionProposalSubmitted('Ya taparon el hueco.'));

      expect(states.last.actionError, contains('Ya hay una propuesta'));
      expect(states.last.resolution?.id, 'res-1');
      expect(states.last.submittedCount, 1, reason: 'the form closes to show the active proposal');
    });

    test('a failure keeps the photo', () async {
      repository.proposeError = Exception('Sin conexión');

      final states = await emittedStates(bloc, const ResolutionProposalSubmitted('Ya taparon el hueco.'));

      expect(states.last.actionError, 'Sin conexión');
      expect(states.last.draftPhoto, isNotNull);
      expect(states.last.submittedCount, 0);
    });

    test('a double tap sends one proposal', () async {
      repository.proposeGate = Completer<void>();
      bloc.add(const ResolutionProposalSubmitted('Ya taparon el hueco.'));
      bloc.add(const ResolutionProposalSubmitted('Ya taparon el hueco.'));
      await pumpEventQueue();
      repository.proposeGate!.complete();
      await pumpEventQueue();

      expect(repository.calls.where((c) => c == 'resolution.propose'), hasLength(1));
    });
  });

  group('votes and decisions', () {
    test('a neighbor confirms and the proposal shows the vote', () async {
      repository.active['inc-1'] = openProposal();
      await open(bloc);

      final states = await emittedStates(bloc, const ResolutionConfirmed());

      expect(states.last.resolution?.hasConfirmed('me'), isTrue);
      expect(states.last.viewerHasVoted, isTrue);
      expect(states.last.notice, contains('confirmación'));
      expect(states.last.reportChangedCount, 0);
    });

    test('when the server resolves it, the proposal leaves and the report reloads (criterion 4)', () async {
      repository.active['inc-1'] = openProposal(confirmerIds: ['v1', 'v2']);
      await open(bloc);
      // The fake does not apply the quorum: the proposal is gone, as the server would leave it.
      repository.active.remove('inc-1');

      final states = await emittedStates(bloc, const ResolutionConfirmed());

      expect(states.last.resolution, isNull);
      expect(states.last.notice, contains('Reparación verificada'));
      expect(states.last.reportChangedCount, 1);
    });

    test('an objection that fails is reported and nothing changes', () async {
      repository.active['inc-1'] = openProposal();
      repository.voteError = Exception('Ya votaste esta propuesta.');
      await open(bloc);

      final states = await emittedStates(bloc, const ResolutionObjected());

      expect(states.last.actionError, 'Ya votaste esta propuesta.');
      expect(states.last.resolution?.objections, 0);
    });

    test('the author accepts and rejects with a reason', () async {
      final authorBloc = buildResolutionBloc(repository, viewerId: 'author-1');
      addTearDown(authorBloc.close);
      repository.active['inc-1'] = openProposal();
      await open(authorBloc);

      final accepted = await emittedStates(authorBloc, const ResolutionAccepted());
      expect(accepted.last.resolution, isNull);
      expect(accepted.last.reportChangedCount, 1);

      repository.active['inc-1'] = openProposal();
      await open(authorBloc);
      final rejected = await emittedStates(authorBloc, const ResolutionRejected('Solo le echaron tierra.'));
      expect(repository.lastReason, 'Solo le echaron tierra.');
      expect(rejected.last.notice, contains('Rechazaste'));
    });

    test('a guest cannot vote', () async {
      final guestBloc = buildResolutionBloc(repository, guest: true);
      addTearDown(guestBloc.close);
      repository.active['inc-1'] = openProposal();
      await open(guestBloc);

      await emittedStates(guestBloc, const ResolutionConfirmed());

      expect(repository.calls, isNot(contains('resolution.confirm')));
    });
  });
}

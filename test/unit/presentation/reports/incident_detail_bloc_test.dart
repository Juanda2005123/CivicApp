import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_incident_by_id_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/toggle_endorsement_usecase.dart';
import 'package:vigia_app/features/reports/ui/bloc/incident_detail_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/incident_detail_event.dart';
import 'package:vigia_app/features/reports/ui/bloc/incident_detail_state.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/fakes.dart';
import '../../../support/incident_samples.dart';

void main() {
  group('IncidentDetailBloc Tests', () {
    late FakeIncidentRepository repository;
    late FakeAuthRepository auth;
    late FakeProfileRepository profiles;
    late IncidentDetailBloc bloc;

    /// A citizen `me` is signed in unless a test signs out first.
    setUp(() {
      repository = FakeIncidentRepository();
      auth = FakeAuthRepository(user: const AuthUser(id: 'me', email: 'me@correo.com'));
      profiles = FakeProfileRepository();
      profiles.stored['me'] = const Profile(id: 'me', email: 'me@correo.com', fullName: 'Vecino Uno', cityName: 'Cali');
      bloc = IncidentDetailBloc(
        GetIncidentByIdUseCase(repository),
        GetCurrentProfileUseCase(auth, profiles),
        ToggleEndorsementUseCase(repository),
      );
    });

    tearDown(() {
      bloc.close();
    });

    /// Opens the report and waits until it is on screen.
    Future<void> openReport() async {
      bloc.add(const IncidentDetailStarted('#VIG-1001'));
      await pumpEventQueue();
    }

    group('IncidentDetailStarted', () {
      test('emits loading and success when the report exists, with the signed-in citizen', () async {
        repository.stored['#VIG-1001'] = sampleIncident();

        final states = await emittedStates(bloc, const IncidentDetailStarted('#VIG-1001'));

        expect(states.map((s) => s.status), [
          IncidentDetailStatus.loading,
          IncidentDetailStatus.success,
        ]);
        expect(states.last.incident?.title, 'Hueco profundo en carril rápido');
        expect(states.last.incident?.trackingCode, '#VIG-1001');
        expect(states.last.viewerId, 'me');
        expect(states.last.isGuest, isFalse);
      });

      test('a guest opens the report with no viewer id', () async {
        auth.user = null;
        repository.stored['#VIG-1001'] = sampleIncident();

        final states = await emittedStates(bloc, const IncidentDetailStarted('#VIG-1001'));

        expect(states.last.status, IncidentDetailStatus.success);
        expect(states.last.viewerId, isNull);
        expect(states.last.isGuest, isTrue);
      });

      test('a profile that cannot be read does not stop the report from opening', () async {
        profiles.getError = Exception('Sin conexión');
        repository.stored['#VIG-1001'] = sampleIncident();

        final states = await emittedStates(bloc, const IncidentDetailStarted('#VIG-1001'));

        expect(states.last.status, IncidentDetailStatus.success);
        expect(states.last.viewerId, isNull);
      });

      test('emits loading and failure when the report does not exist', () async {
        final states = await emittedStates(bloc, const IncidentDetailStarted('non-existent'));

        expect(states.map((s) => s.status), [
          IncidentDetailStatus.loading,
          IncidentDetailStatus.failure,
        ]);
        expect(states.last.errorMessage, isNotNull);
      });

      test('knows when the citizen is the author and when they already endorsed', () async {
        repository.stored['#VIG-1001'] = sampleIncident(reporterId: 'me');
        await openReport();
        expect(bloc.state.viewerIsAuthor, isTrue);

        repository.stored['#VIG-1001'] = sampleIncident(upvoterIds: ['me'], upvotesCount: 1);
        await openReport();
        expect(bloc.state.viewerIsAuthor, isFalse);
        expect(bloc.state.viewerEndorsed, isTrue);
      });
    });

    group('IncidentEndorsementToggled', () {
      setUp(() {
        repository.stored['inc-1'] = sampleIncident(upvotesCount: 3);
        repository.stored['#VIG-1001'] = repository.stored['inc-1']!;
      });

      test('draws the endorsement at once, saves it and reads the report again', () async {
        await openReport();
        repository.calls.clear();

        final states = await emittedStates(bloc, const IncidentEndorsementToggled());

        expect(states.first.isEndorsing, isTrue);
        expect(states.first.incident?.upvotesCount, 4, reason: 'drawn before the server answers');
        expect(states.first.viewerEndorsed, isTrue);
        expect(states.last.isEndorsing, isFalse);
        expect(states.last.incident?.upvotesCount, 4);
        expect(states.last.endorsementError, isNull);
        expect(repository.calls, ['incident.endorse', 'incident.getById']);
      });

      test('a second tap revokes the endorsement', () async {
        repository.stored['inc-1'] = sampleIncident(upvoterIds: ['me', 'v2', 'v3'], upvotesCount: 3);
        repository.stored['#VIG-1001'] = repository.stored['inc-1']!;
        await openReport();
        repository.calls.clear();

        final states = await emittedStates(bloc, const IncidentEndorsementToggled());

        expect(states.first.incident?.upvotesCount, 2);
        expect(states.last.viewerEndorsed, isFalse);
        expect(repository.calls, ['incident.revoke', 'incident.getById']);
      });

      test('a failed request puts the report back and tells why (HU-15, criterion 5)', () async {
        await openReport();
        repository.endorseError = Exception('Sin conexión');

        final states = await emittedStates(bloc, const IncidentEndorsementToggled());

        expect(states.first.incident?.upvotesCount, 4);
        expect(states.last.incident?.upvotesCount, 3);
        expect(states.last.viewerEndorsed, isFalse);
        expect(states.last.isEndorsing, isFalse);
        expect(states.last.endorsementError, 'Sin conexión');
      });

      test('the tap of the author is refused with a clear message and changes nothing', () async {
        repository.stored['inc-1'] = sampleIncident(reporterId: 'me', upvotesCount: 3);
        repository.stored['#VIG-1001'] = repository.stored['inc-1']!;
        await openReport();
        repository.calls.clear();

        final states = await emittedStates(bloc, const IncidentEndorsementToggled());

        expect(states.last.incident?.upvotesCount, 3);
        expect(states.last.endorsementError, 'No puedes apoyar tu propio reporte.');
        expect(repository.calls, isEmpty);
      });

      test('a guest tap does nothing', () async {
        auth.user = null;
        await openReport();
        repository.calls.clear();

        final states = await emittedStates(bloc, const IncidentEndorsementToggled());

        expect(states, isEmpty);
        expect(repository.calls, isEmpty);
      });

      test('a tap while the previous one is still running is ignored', () async {
        await openReport();
        repository.calls.clear();
        repository.endorseGate = Completer<void>();

        bloc.add(const IncidentEndorsementToggled());
        await pumpEventQueue();
        bloc.add(const IncidentEndorsementToggled());
        await pumpEventQueue();
        repository.endorseGate!.complete();
        await pumpEventQueue();

        expect(repository.calls.where((c) => c == 'incident.endorse'), hasLength(1));
        expect(bloc.state.incident?.upvotesCount, 4);
      });

      test('if reading the report again fails, the saved endorsement stays drawn', () async {
        await openReport();
        repository.getError = Exception('Sin conexión');

        final states = await emittedStates(bloc, const IncidentEndorsementToggled());

        expect(states.last.isEndorsing, isFalse);
        expect(states.last.incident?.upvotesCount, 4);
        expect(states.last.endorsementError, isNull);
      });

      test('the 10th endorsement shows the validated report the server returns', () async {
        repository.stored['inc-1'] = sampleIncident(upvotesCount: 9);
        repository.stored['#VIG-1001'] = repository.stored['inc-1']!;
        await openReport();
        expect(bloc.state.incident?.isCommunityValidated, isFalse);

        final states = await emittedStates(bloc, const IncidentEndorsementToggled());

        expect(states.first.incident?.upvotesCount, 10);
        expect(states.first.incident?.isCommunityValidated, isFalse, reason: 'only the server validates');
        expect(states.last.incident?.isCommunityValidated, isTrue);
        expect(states.last.incident?.validatedAt, isNotNull);
      });
    });
  });
}

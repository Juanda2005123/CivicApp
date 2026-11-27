import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/dashboard/domain/entities/civic_impact.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_event.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_state.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/fake_impact_repository.dart';
import '../../../support/fakes.dart';
import '../../../support/profile_bloc_factory.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeImpactRepository impact;

  const citizen = Profile(
    id: 'uid-1',
    email: 'ana@example.com',
    fullName: 'Ana Cívica',
    cityName: 'Cali',
    rankId: 2,
    rankName: 'Vecino Vigilante',
    experiencePoints: 1750,
  );

  ProfileBloc newBloc() {
    final bloc = buildProfileBloc(auth, profiles, impact: impact);
    addTearDown(bloc.close);
    return bloc;
  }

  setUp(() {
    auth = FakeAuthRepository(user: const AuthUser(id: 'uid-1', email: 'ana@example.com'));
    profiles = FakeProfileRepository()..stored['uid-1'] = citizen;
    impact = FakeImpactRepository()
      ..impact = const CivicImpact(
        reportsCreated: 3,
        endorsementsReceived: 12,
        endorsementsGiven: 7,
        commentsPublished: 5,
      );
  });

  group('ProfileBloc impact dashboard (HU-23)', () {
    test('ProfileStarted loads the profile first and then the impact', () async {
      final states = await emittedStates(newBloc(), ProfileStarted());

      // The profile is on screen before the counters arrive.
      final withProfileOnly = states.firstWhere((s) => s.status == ProfileStatus.success);
      expect(withProfileOnly.profile, citizen);
      expect(withProfileOnly.impactStatus, ImpactStatus.loading);

      final last = states.last;
      expect(last.impactStatus, ImpactStatus.success);
      expect(last.impact?.reportsCreated, 3);
      expect(last.impact?.endorsementsReceived, 12);
      expect(last.impact?.endorsementsGiven, 7);
      expect(last.impact?.commentsPublished, 5);
    });

    test('the rank progress is computed from the experience points of the profile', () async {
      final states = await emittedStates(newBloc(), ProfileStarted());

      final progress = states.last.rankProgress!;
      expect(progress.current.id, 2);
      expect(progress.next?.id, 3);
      expect(progress.fraction, closeTo(0.5, 0.0001));
    });

    test('a citizen at the highest rank gets a full bar and no next rank (criterion 4)', () async {
      profiles.stored['uid-1'] = const Profile(
        id: 'uid-1',
        email: 'ana@example.com',
        fullName: 'Ana Cívica',
        cityName: 'Cali',
        rankId: 4,
        rankName: 'Veedor Mayor',
        experiencePoints: 4300,
      );

      final states = await emittedStates(newBloc(), ProfileStarted());

      expect(states.last.rankProgress?.isMaxRank, isTrue);
      expect(states.last.rankProgress?.fraction, 1);
    });

    test('the citizen has no reports yet: the list is empty, not an error', () async {
      final states = await emittedStates(newBloc(), ProfileStarted());

      expect(states.last.myReports, isEmpty);
      expect(states.last.impactStatus, ImpactStatus.success);
    });

    test('the impact is read for the citizen of the session only', () async {
      await emittedStates(newBloc(), ProfileStarted());

      expect(impact.calls, containsAll(['impact.get:uid-1', 'impact.reports:uid-1', 'impact.ranks']));
    });

    test('a failure reading the counters keeps the profile and offers a retry', () async {
      impact.impactError = Exception('No pudimos cargar tu impacto: permission denied');

      final states = await emittedStates(newBloc(), ProfileStarted());

      expect(states.last.status, ProfileStatus.success);
      expect(states.last.profile, citizen);
      expect(states.last.impactStatus, ImpactStatus.failure);
      expect(states.last.impactErrorMessage, 'No pudimos cargar tu impacto: permission denied');
    });

    test('a guest never asks for an impact', () async {
      auth.user = null;

      final states = await emittedStates(newBloc(), ProfileStarted());

      expect(states.last.status, ProfileStatus.guest);
      expect(impact.calls, isEmpty);
    });

    test('ProfileRefreshed updates the numbers without a loading state in between', () async {
      final bloc = newBloc();
      await emittedStates(bloc, ProfileStarted());

      impact.impact = const CivicImpact(reportsCreated: 4, endorsementsReceived: 15, commentsPublished: 6);
      profiles.stored['uid-1'] = const Profile(
        id: 'uid-1',
        email: 'ana@example.com',
        fullName: 'Ana Cívica',
        cityName: 'Cali',
        rankId: 3,
        rankName: 'Guardián Cívico',
        experiencePoints: 2600,
      );

      final states = await emittedStates(bloc, ProfileRefreshed());

      expect(states.map((s) => s.status), everyElement(ProfileStatus.success));
      expect(states.map((s) => s.impactStatus), isNot(contains(ImpactStatus.loading)));
      expect(states.last.impact?.reportsCreated, 4);
      expect(states.last.impact?.endorsementsReceived, 15);
      // The rank follows the experience points the server computed (RN-09, criterion 3).
      expect(states.last.profile?.rankId, 3);
      expect(states.last.rankProgress?.current.id, 3);
    });

    test('a failed refresh keeps the numbers that were already on screen', () async {
      final bloc = newBloc();
      await emittedStates(bloc, ProfileStarted());
      impact.impactError = Exception('Sin conexión');

      final states = await emittedStates(bloc, ProfileRefreshed());

      expect(states.last.impact?.reportsCreated, 3);
      expect(states.last.impactStatus, ImpactStatus.success);
      expect(states.last.impactErrorMessage, 'Sin conexión');
    });

    test('ProfileStarted again after a failure recovers the impact', () async {
      impact.impactError = Exception('Sin conexión');
      final bloc = newBloc();
      await emittedStates(bloc, ProfileStarted());
      impact.impactError = null;

      final states = await emittedStates(bloc, ProfileStarted());

      expect(states.last.impactStatus, ImpactStatus.success);
      expect(states.last.impact?.reportsCreated, 3);
      expect(states.last.impactErrorMessage, isNull);
    });
  });
}

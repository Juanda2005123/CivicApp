import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/widgets/city/celebration_overlay.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_event.dart';
import 'package:vigia_app/features/dashboard/ui/pages/profile_page.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/ui/bloc/comments_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/incident_detail_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/resolution_bloc.dart';
import 'package:vigia_app/features/reports/ui/screens/incident_detail_screen.dart';

import '../../support/city_theme_host.dart';
import '../../support/detail_bloc_factory.dart';
import '../../support/fake_comment_repository.dart';
import '../../support/fake_impact_repository.dart';
import '../../support/fake_resolution_repository.dart';
import '../../support/fakes.dart';
import '../../support/incident_samples.dart';
import '../../support/profile_bloc_factory.dart';

void main() {
  group('validated report (3A) on the detail', () {
    late FakeIncidentRepository repository;

    Future<void> openReport(WidgetTester tester, Incident incident) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      repository = FakeIncidentRepository()
        ..stored['#VIG-1001'] = incident
        ..stored[incident.id] = incident;
      final bloc = buildDetailBloc(repository);
      addTearDown(bloc.close);
      final comments = buildCommentsBloc(FakeCommentRepository());
      addTearDown(comments.close);
      final resolution = buildResolutionBloc(FakeResolutionRepository());
      addTearDown(resolution.close);

      await tester.pumpWidget(cityHost(
        MultiBlocProvider(
          providers: [
            BlocProvider<IncidentDetailBloc>.value(value: bloc),
            BlocProvider<CommentsBloc>.value(value: comments),
            BlocProvider<ResolutionBloc>.value(value: resolution),
          ],
          child: const IncidentDetailScreen(incidentIdOrCode: '#VIG-1001'),
        ),
        city: 'Cali',
        scaffold: false,
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('the 10th endorsement celebrates once', (tester) async {
      await openReport(tester, sampleIncident(upvotesCount: 9));
      expect(find.byType(ValidationCelebration), findsNothing);

      await tester.tap(find.text('Apoyar este reporte'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ValidationCelebration), findsOneWidget);
      expect(find.text('¡Eso, ve!'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(ValidationCelebration), findsNothing);
    });

    testWidgets('the endorsements before the 10th do not celebrate', (tester) async {
      await openReport(tester, sampleIncident(upvotesCount: 4));

      await tester.tap(find.text('Apoyar este reporte'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ValidationCelebration), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('endorsing again a report already validated does not celebrate', (tester) async {
      await openReport(
        tester,
        sampleIncident(
          upvotesCount: 11,
          status: IncidentStatus.communityValidated,
          validatedAt: DateTime(2026, 11, 15),
        ),
      );

      await tester.tap(find.text('Apoyar este reporte'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ValidationCelebration), findsNothing);
      await tester.pumpAndSettle();
    });
  });

  group('new rank (4C) on "Mi perfil"', () {
    late FakeProfileRepository profiles;
    late ProfileBloc bloc;
    late ValueNotifier<bool> inSight;

    Profile citizen(int xp, int rankId) => Profile(
          id: 'uid-1',
          email: 'ana@example.com',
          fullName: 'Ana Cívica',
          cityName: 'Cali',
          rankId: rankId,
          experiencePoints: xp,
        );

    Future<void> openProfile(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = FakeAuthRepository(user: const AuthUser(id: 'uid-1', email: 'ana@example.com'));
      profiles = FakeProfileRepository()..stored['uid-1'] = citizen(900, 1);
      inSight = ValueNotifier(true);
      addTearDown(inSight.dispose);
      bloc = buildProfileBloc(auth, profiles, impact: FakeImpactRepository())..add(ProfileStarted());
      addTearDown(bloc.close);

      await tester.pumpWidget(cityHost(
        BlocProvider<ProfileBloc>.value(
          value: bloc,
          child: ValueListenableBuilder<bool>(
            valueListenable: inSight,
            builder: (context, visible, child) => TickerMode(enabled: visible, child: child!),
            child: ProfilePage(onReportPressed: () {}),
          ),
        ),
        city: 'Cali',
      ));
      await tester.pumpAndSettle();
    }

    Future<void> earn(WidgetTester tester, int xp, int rankId) async {
      profiles.stored['uid-1'] = citizen(xp, rankId);
      bloc.add(ProfileRefreshed());
      // The reload, the scroll to the medal and the start of the circle.
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('reaching a new rank opens the photo of its place', (tester) async {
      await openProfile(tester);
      expect(find.byType(RankCelebration), findsNothing, reason: 'the first load is not a new rank');

      await earn(tester, 1000, 2);

      expect(find.byType(RankCelebration), findsOneWidget);
      expect(find.text('NUEVO RANGO · VECINO VIGILANTE'), findsOneWidget);
      expect(find.descendant(of: find.byType(RankCelebration), matching: find.text('La Ermita')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(RankCelebration), findsNothing);
      expect(find.text('Vas por La Ermita'), findsOneWidget);
    });

    testWidgets('more points in the same rank do not celebrate', (tester) async {
      await openProfile(tester);

      await earn(tester, 950, 1);

      expect(find.byType(RankCelebration), findsNothing);
    });

    testWidgets('in a hidden tab it waits until the citizen comes back', (tester) async {
      await openProfile(tester);
      inSight.value = false;
      await tester.pump();

      await earn(tester, 1200, 2);
      expect(find.byType(RankCelebration), findsNothing);

      inSight.value = true;
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(RankCelebration), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}

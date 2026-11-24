import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/dashboard/domain/entities/civic_impact.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_event.dart';
import 'package:vigia_app/features/dashboard/ui/pages/profile_page.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';

import '../support/fake_impact_repository.dart';
import '../support/fakes.dart';
import '../support/profile_bloc_factory.dart';

FeedIncident _myReport({String id = 'inc-1', String code = '#VIG-1001', String title = 'Hueco en la Calle 5'}) {
  return FeedIncident(
    id: id,
    trackingCode: code,
    title: title,
    neighborhood: 'Tequendama',
    categoryName: 'Hueco',
    categoryIcon: 'traffic',
    severity: IncidentSeverity.high,
    status: IncidentStatus.reported,
    coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
    createdAt: DateTime(2026, 11, 12),
    upvotesCount: 4,
    commentsCount: 2,
  );
}

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeImpactRepository impact;
  var reportPressed = 0;

  Profile citizen({int xp = 1750, int rankId = 2, String rankName = 'Vecino Vigilante'}) => Profile(
        id: 'uid-1',
        email: 'ana@example.com',
        fullName: 'Ana Cívica',
        cityName: 'Cali',
        rankId: rankId,
        rankName: rankName,
        experiencePoints: xp,
      );

  /// A tall screen so the whole dashboard is laid out without scrolling.
  Future<void> openProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final bloc = buildProfileBloc(auth, profiles, impact: impact)..add(ProfileStarted());
    addTearDown(bloc.close);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: BlocProvider<ProfileBloc>.value(
          value: bloc,
          child: ProfilePage(onReportPressed: () => reportPressed++),
        ),
      ),
      routes: {
        AppRoutes.reportDetail: (context) => Scaffold(
              body: Text('Detalle ${ModalRoute.of(context)!.settings.arguments}'),
            ),
      },
    ));
    await tester.pumpAndSettle();
  }

  setUp(() {
    reportPressed = 0;
    auth = FakeAuthRepository(user: const AuthUser(id: 'uid-1', email: 'ana@example.com'));
    profiles = FakeProfileRepository()..stored['uid-1'] = citizen();
    impact = FakeImpactRepository()
      ..impact = const CivicImpact(
        reportsCreated: 3,
        endorsementsReceived: 12,
        endorsementsGiven: 7,
        commentsPublished: 5,
      );
  });

  group('Mi perfil, civic impact dashboard (HU-23)', () {
    testWidgets('shows the role and the four counters with their real totals (criterion 2)', (tester) async {
      await openProfile(tester);

      expect(find.text('Ciudadano'), findsOneWidget);
      for (final (label, value) in [
        ('Reportes creados', '3'),
        ('Apoyos recibidos', '12'),
        ('Apoyos otorgados', '7'),
        ('Comentarios publicados', '5'),
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
        expect(find.bySemanticsLabel('$value ${label.toLowerCase()}'), findsOneWidget, reason: label);
      }
    });

    testWidgets('draws the progress to the next rank (criterion 1)', (tester) async {
      await openProfile(tester);

      expect(find.text('Tu avance'), findsOneWidget);
      expect(find.text('1750 / 2500 pts'), findsOneWidget);
      expect(find.text('Te faltan 750 pts para el Nivel 3 · Guardián Cívico.'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(bar.value, closeTo(0.5, 0.0001));
    });

    testWidgets('at the highest rank the bar is full and says so (criterion 4)', (tester) async {
      profiles.stored['uid-1'] = citizen(xp: 4300, rankId: 4, rankName: 'Veedor Mayor');
      await openProfile(tester);

      expect(find.text('Llegaste al nivel más alto. Gracias por vigilar tu ciudad.'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(bar.value, 1);
    });

    testWidgets('lists "Mis reportes" and opens the detail of the tapped one (criterion 5)', (tester) async {
      impact.myReports = [_myReport(), _myReport(id: 'inc-2', code: '#VIG-1002', title: 'Alcantarilla abierta')];
      await openProfile(tester);

      expect(find.text('Mis reportes'), findsOneWidget);
      expect(find.text('Hueco en la Calle 5'), findsOneWidget);
      expect(find.text('Alcantarilla abierta'), findsOneWidget);

      await tester.tap(find.text('Alcantarilla abierta'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle inc-2'), findsOneWidget);
    });

    testWidgets('with no reports it invites the citizen to publish the first one (criterion 5)', (tester) async {
      await openProfile(tester);

      expect(find.text('Aún no has publicado reportes.'), findsOneWidget);

      await tester.tap(find.text('Reportar mi primer daño'));
      await tester.pump();

      expect(reportPressed, 1);
    });

    testWidgets('leaves room under "Cerrar sesión" so the report button of the shell does not cover it',
        (tester) async {
      await openProfile(tester);

      final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));

      expect(scroll.padding?.resolve(TextDirection.ltr).bottom, greaterThanOrEqualTo(ProfilePage.bottomClearance));
    });

    testWidgets('when the counters cannot load, it says why, keeps the profile and offers a retry', (tester) async {
      impact.impactError = Exception('No pudimos cargar tu impacto: sin conexión');
      await openProfile(tester);

      expect(find.text('No pudimos cargar tu impacto: sin conexión'), findsOneWidget);
      expect(find.text('Ana Cívica'), findsOneWidget);
      expect(find.text('Reportes creados'), findsNothing);
      expect(find.text('Mis reportes'), findsNothing, reason: 'an empty list here would be a false "no reports"');

      impact.impactError = null;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Reportes creados'), findsOneWidget);
      expect(find.text('No pudimos cargar tu impacto: sin conexión'), findsNothing);
    });
  });
}

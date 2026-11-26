import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/widgets/validation_seal.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/ui/bloc/comments_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/resolution_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/incident_detail_bloc.dart';
import 'package:vigia_app/features/reports/ui/screens/incident_detail_screen.dart';

import '../../support/detail_bloc_factory.dart';
import '../../support/fake_comment_repository.dart';
import '../../support/fake_resolution_repository.dart';
import '../../support/fakes.dart';
import '../../support/incident_samples.dart';

void main() {
  group('IncidentDetailScreen endorsements (HU-15, HU-16)', () {
    late FakeIncidentRepository repository;

    setUp(() {
      repository = FakeIncidentRepository();
    });

    /// A tall screen, so the endorse button is on screen without scrolling.
    Future<IncidentDetailBloc> openReport(
      WidgetTester tester,
      Incident incident, {
      bool guest = false,
    }) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      repository.stored['#VIG-1001'] = incident;
      repository.stored[incident.id] = incident;
      final bloc = buildDetailBloc(repository, guest: guest);
      addTearDown(bloc.close);

      final commentsBloc = buildCommentsBloc(FakeCommentRepository(), guest: guest);
      final resolutionBloc = buildResolutionBloc(FakeResolutionRepository(), guest: guest);
      addTearDown(resolutionBloc.close);
      addTearDown(commentsBloc.close);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<IncidentDetailBloc>.value(value: bloc),
            BlocProvider<CommentsBloc>.value(value: commentsBloc),
            BlocProvider<ResolutionBloc>.value(value: resolutionBloc),
          ],
          child: const IncidentDetailScreen(incidentIdOrCode: '#VIG-1001'),
        ),
      ));
      await tester.pumpAndSettle();
      return bloc;
    }

    testWidgets('a citizen who has not endorsed sees "Apoyar este reporte" and how many are missing', (tester) async {
      await openReport(tester, sampleIncident(upvotesCount: 4));

      expect(find.text('Apoyar este reporte'), findsOneWidget);
      expect(find.text('Apoyado'), findsNothing);
      expect(find.text('4 de 10 apoyos'), findsOneWidget);
      expect(find.text('Faltan 6 apoyos para validar este reporte (+500 XP).'), findsOneWidget);
    });

    testWidgets('the missing count is singular when only one endorsement is left', (tester) async {
      await openReport(tester, sampleIncident(upvotesCount: 9));

      expect(find.text('Faltan 1 apoyo para validar este reporte (+500 XP).'), findsOneWidget);
    });

    testWidgets('tapping "Apoyar" adds the endorsement and the button becomes "Apoyado"', (tester) async {
      await openReport(tester, sampleIncident(upvotesCount: 4));

      await tester.tap(find.text('Apoyar este reporte'));
      await tester.pumpAndSettle();

      expect(find.text('5 de 10 apoyos'), findsOneWidget);
      expect(find.text('Apoyado'), findsOneWidget);
      expect(find.text('Apoyar este reporte'), findsNothing);
      expect(repository.calls, contains('incident.endorse'));
    });

    testWidgets('tapping "Apoyado" takes the endorsement back', (tester) async {
      await openReport(tester, sampleIncident(upvoterIds: ['me', 'v2', 'v3', 'v4'], upvotesCount: 4));
      expect(find.text('Apoyado'), findsOneWidget);

      await tester.tap(find.text('Apoyado'));
      await tester.pumpAndSettle();

      expect(find.text('3 de 10 apoyos'), findsOneWidget);
      expect(find.text('Apoyar este reporte'), findsOneWidget);
      expect(repository.calls, contains('incident.revoke'));
    });

    testWidgets('the author has no endorse button on their own report (RN-05)', (tester) async {
      await openReport(tester, sampleIncident(reporterId: 'me', upvotesCount: 4));

      expect(find.text('Apoyar este reporte'), findsNothing);
      expect(find.text('Apoyado'), findsNothing);
      expect(find.text('4 de 10 apoyos'), findsOneWidget);
    });

    testWidgets('a guest who taps "Apoyar" gets the sign-in modal and nothing is saved (HU-22)', (tester) async {
      await openReport(tester, sampleIncident(upvotesCount: 4), guest: true);

      await tester.tap(find.text('Apoyar este reporte'));
      await tester.pumpAndSettle();

      expect(find.text('Necesitas iniciar sesión'), findsOneWidget);
      expect(find.textContaining('Para apoyar un reporte necesitas una cuenta'), findsOneWidget);
      expect(repository.calls, isNot(contains('incident.endorse')));

      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      expect(find.text('Necesitas iniciar sesión'), findsNothing);
      expect(find.text('4 de 10 apoyos'), findsOneWidget);
    });

    testWidgets('a failed endorsement puts the count back and shows why', (tester) async {
      await openReport(tester, sampleIncident(upvotesCount: 4));
      repository.endorseError = Exception('Sin conexión');

      await tester.tap(find.text('Apoyar este reporte'));
      await tester.pumpAndSettle();

      expect(find.text('4 de 10 apoyos'), findsOneWidget);
      expect(find.text('Apoyar este reporte'), findsOneWidget);
      expect(find.text('Sin conexión'), findsOneWidget);
    });

    testWidgets('the 10th endorsement shows the validation seal', (tester) async {
      await openReport(tester, sampleIncident(upvotesCount: 9));
      expect(find.byType(ValidationSeal), findsNothing);

      await tester.tap(find.text('Apoyar este reporte'));
      await tester.pumpAndSettle();

      expect(find.byType(ValidationSeal), findsOneWidget);
      expect(find.text('Reporte validado por la comunidad'), findsOneWidget);
      expect(find.text('10 de 10 apoyos'), findsOneWidget);
      expect(find.textContaining('Faltan'), findsNothing);
    });

    testWidgets('a validated report keeps its seal after the count drops under 10 (HU-16, criterion 5)', (tester) async {
      await openReport(
        tester,
        sampleIncident(
          upvoterIds: ['me', 'v2', 'v3', 'v4', 'v5', 'v6', 'v7', 'v8', 'v9', 'v10'],
          upvotesCount: 10,
          status: IncidentStatus.communityValidated,
          validatedAt: DateTime(2026, 11, 15),
        ),
      );
      expect(find.byType(ValidationSeal), findsOneWidget);

      await tester.tap(find.text('Apoyado'));
      await tester.pumpAndSettle();

      expect(find.text('9 de 10 apoyos'), findsOneWidget);
      expect(find.byType(ValidationSeal), findsOneWidget);
      expect(find.text('Los vecinos ya validaron este reporte.'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/ui/bloc/comments_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/incident_detail_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/resolution_bloc.dart';
import 'package:vigia_app/features/reports/ui/screens/incident_detail_screen.dart';

import '../../support/comment_samples.dart';
import '../../support/detail_bloc_factory.dart';
import '../../support/fake_comment_repository.dart';
import '../../support/fake_resolution_repository.dart';
import '../../support/fakes.dart';
import '../../support/incident_samples.dart';
import '../../support/resolution_samples.dart';

void main() {
  group('IncidentDetailScreen community resolution (HU-25)', () {
    late FakeIncidentRepository incidents;
    late FakeResolutionRepository resolutions;

    setUp(() {
      incidents = FakeIncidentRepository();
      resolutions = FakeResolutionRepository();
    });

    /// A tall screen, so the resolution block is on screen without scrolling.
    Future<void> openReport(
      WidgetTester tester,
      Incident incident, {
      bool guest = false,
      ThemeData? theme,
    }) async {
      tester.view.physicalSize = const Size(800, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      incidents.stored['#VIG-1001'] = incident;
      incidents.stored[incident.id] = incident;
      resolutions.reporterOf[incident.id] = incident.reporterId;

      final detailBloc = buildDetailBloc(incidents, guest: guest);
      final commentsBloc = buildCommentsBloc(FakeCommentRepository(), guest: guest);
      final resolutionBloc = buildResolutionBloc(
        resolutions,
        guest: guest,
        picker: FakePhotoPickerRepository(photoToReturn: samplePhoto()),
      );
      addTearDown(detailBloc.close);
      addTearDown(commentsBloc.close);
      addTearDown(resolutionBloc.close);

      await tester.pumpWidget(MaterialApp(
        theme: theme ?? AppTheme.light,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<IncidentDetailBloc>.value(value: detailBloc),
            BlocProvider<CommentsBloc>.value(value: commentsBloc),
            BlocProvider<ResolutionBloc>.value(value: resolutionBloc),
          ],
          child: const IncidentDetailScreen(incidentIdOrCode: '#VIG-1001'),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('a neighbor proposes the repair with a photo and a description (criterion 1)', (tester) async {
      await openReport(tester, sampleIncident());

      await tester.tap(find.text('Reportar como reparado'));
      await tester.pumpAndSettle();

      final send = find.widgetWithText(FilledButton, 'Enviar evidencia');
      expect(tester.widget<FilledButton>(send).onPressed, isNull, reason: 'no photo and no text yet');

      await tester.tap(find.text('Galería'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Ya taparon el hueco con asfalto.');
      await tester.pump();
      expect(tester.widget<FilledButton>(send).onPressed, isNotNull);

      await tester.tap(send);
      await tester.pumpAndSettle();

      expect(resolutions.calls, contains('resolution.propose'));
      expect(find.text('Reparación en verificación'), findsOneWidget);
      expect(find.text('Reportar como reparado'), findsNothing);
    });

    testWidgets('a neighbor confirms a pending proposal and the card says they voted', (tester) async {
      resolutions.active['inc-1'] = sampleResolution(proposedAt: DateTime.now(), confirmerIds: ['v1']);
      await openReport(tester, sampleIncident(status: IncidentStatus.underReview));

      expect(find.text('Reparación en verificación'), findsOneWidget);
      expect(find.text('1 de 3'), findsOneWidget);
      expect(find.text('Reportar como reparado'), findsNothing, reason: 'one pending proposal per report (criterion 2)');

      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(resolutions.calls, contains('resolution.confirm'));
      expect(find.text('2 de 3'), findsOneWidget);
      expect(find.text('Ya votaste esta propuesta. Gracias por verificar.'), findsOneWidget);
    });

    testWidgets('the author rejects a proposal only with a reason', (tester) async {
      resolutions.active['inc-1'] = sampleResolution(proposedAt: DateTime.now());
      await openReport(tester, sampleIncident(reporterId: 'me', status: IncidentStatus.underReview));

      expect(find.text('Aceptar'), findsOneWidget);
      expect(find.text('Confirmar'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Rechazar'));
      await tester.pumpAndSettle();
      final reject = find.widgetWithText(FilledButton, 'Rechazar');
      await tester.enterText(find.byType(TextField).last, 'No');
      await tester.pump();
      expect(tester.widget<FilledButton>(reject).onPressed, isNull);

      await tester.enterText(find.byType(TextField).last, 'Solo le echaron tierra.');
      await tester.pump();
      await tester.tap(reject);
      await tester.pumpAndSettle();

      expect(resolutions.lastReason, 'Solo le echaron tierra.');
      expect(find.text('Reparación en verificación'), findsNothing);
    });

    testWidgets('a guest is asked to sign in before proposing', (tester) async {
      await openReport(tester, sampleIncident(), guest: true);

      await tester.tap(find.text('Reportar como reparado'));
      await tester.pumpAndSettle();

      expect(find.text('Necesitas iniciar sesión'), findsOneWidget);
      expect(resolutions.calls, isNot(contains('resolution.propose')));
    });

    testWidgets('a resolved report says so and offers no proposal', (tester) async {
      await openReport(tester, sampleIncident(status: IncidentStatus.resolved));

      expect(find.textContaining('Reparación verificada'), findsOneWidget);
      expect(find.text('Reportar como reparado'), findsNothing);
    });

    testWidgets('the pinned card works in the dark theme', (tester) async {
      resolutions.active['inc-1'] = sampleResolution(proposedAt: DateTime.now());
      await openReport(tester, sampleIncident(status: IncidentStatus.underReview), theme: AppTheme.dark);

      expect(find.text('Reparación en verificación'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

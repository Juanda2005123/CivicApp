import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/ui/bloc/comments_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/incident_detail_bloc.dart';
import 'package:vigia_app/features/reports/ui/screens/incident_detail_screen.dart';
import 'package:vigia_app/features/reports/ui/widgets/author_actions_card.dart';

import '../../support/detail_bloc_factory.dart';
import '../../support/fake_comment_repository.dart';
import '../../support/fakes.dart';
import '../../support/incident_samples.dart';

/// A report the signed-in citizen `me` published [minutes] minutes ago.
Incident _own({int minutes = 5, int upvotes = 0}) => sampleIncident(
      reporterId: 'me',
      upvotesCount: upvotes,
      createdAt: DateTime.now().subtract(Duration(minutes: minutes)),
    );

void main() {
  late FakeIncidentRepository repository;

  setUp(() => repository = FakeIncidentRepository());

  /// The detail is opened from a home with one button, so a pop is visible.
  Future<void> openDetail(WidgetTester tester, Incident incident) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    repository.stored['#VIG-1001'] = incident;
    repository.stored[incident.id] = incident;
    final bloc = buildDetailBloc(repository);
    addTearDown(bloc.close);
    final commentsBloc = buildCommentsBloc(FakeCommentRepository());
    addTearDown(commentsBloc.close);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      routes: {
        AppRoutes.reportEdit: (context) => const Scaffold(body: Text('Formulario de edición')),
      },
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider<IncidentDetailBloc>.value(value: bloc),
                    BlocProvider<CommentsBloc>.value(value: commentsBloc),
                  ],
                  child: const IncidentDetailScreen(incidentIdOrCode: '#VIG-1001'),
                ),
              )),
              child: const Text('Abrir reporte'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir reporte'));
    await tester.pumpAndSettle();
  }

  group('Author actions on the detail (HU-18)', () {
    testWidgets('inside the window and under 5 endorsements the author sees Editar and Eliminar (criterion 1)',
        (tester) async {
      await openDetail(tester, _own(minutes: 5, upvotes: 2));

      expect(find.text('Tu reporte'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
      expect(find.textContaining('durante 25 min más'), findsOneWidget);
      expect(find.text('Reporte congelado'), findsNothing);
    });

    testWidgets('after 30 minutes the actions are gone and the report is frozen (criterion 4)', (tester) async {
      await openDetail(tester, _own(minutes: 45));

      expect(find.text('Reporte congelado'), findsOneWidget);
      expect(find.text('Editar'), findsNothing);
      expect(find.text('Eliminar'), findsNothing);
    });

    testWidgets('with 5 endorsements it is frozen even on the first minute (criterion 4)', (tester) async {
      await openDetail(tester, _own(minutes: 1, upvotes: 5));

      expect(find.text('Reporte congelado'), findsOneWidget);
      expect(find.text('Editar'), findsNothing);
    });

    testWidgets('a citizen who did not write the report sees neither the actions nor the frozen note', (tester) async {
      await openDetail(
        tester,
        sampleIncident(reporterId: 'author-1', createdAt: DateTime.now().subtract(const Duration(minutes: 2))),
      );

      expect(find.text('Tu reporte'), findsNothing);
      expect(find.text('Reporte congelado'), findsNothing);
      expect(find.text('Editar'), findsNothing);
    });

    testWidgets('Editar opens the edit form', (tester) async {
      await openDetail(tester, _own());

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.text('Formulario de edición'), findsOneWidget);
    });

    testWidgets('Eliminar asks first; Cancelar deletes nothing', (tester) async {
      await openDetail(tester, _own());

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(find.text('¿Eliminar este reporte?'), findsOneWidget);
      expect(find.textContaining('100 XP'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repository.deletedIds, isEmpty);
      expect(find.text('Tu reporte'), findsOneWidget);
    });

    testWidgets('confirming deletes the report and leaves the detail (criterion 3)', (tester) async {
      await openDetail(tester, _own());

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(repository.deletedIds, ['inc-1']);
      expect(find.text('Abrir reporte'), findsOneWidget, reason: 'the detail closed');
      expect(find.text('Reporte eliminado.'), findsOneWidget);
    });

    testWidgets('when the server refuses the delete the report stays and the reason shows (criterion 5)',
        (tester) async {
      await openDetail(tester, _own());
      repository.deleteError = Exception(
        'Este reporte ya no se puede modificar ni eliminar: pasaron más de 30 minutos o tiene 5 apoyos o más.',
      );

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('pasaron más de 30 minutos'), findsOneWidget);
      expect(find.text('Tu reporte'), findsOneWidget, reason: 'still on the detail');
    });
  });

  group('AuthorActionsCard', () {
    testWidgets('the buttons disappear by themselves when the window closes with the screen open', (tester) async {
      // 600 ms of window left.
      final incident = sampleIncident(
        reporterId: 'me',
        createdAt: DateTime.now().subtract(Incident.editWindow - const Duration(milliseconds: 600)),
      );

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AuthorActionsCard(
            incident: incident,
            viewerId: 'me',
            checkEvery: const Duration(milliseconds: 100),
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ));
      expect(find.text('Editar'), findsOneWidget);

      // The clock is the real one: let the window really close, then let the timer fire.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 900)));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Editar'), findsNothing);
      expect(find.text('Reporte congelado'), findsOneWidget);
    });

    test('formatTimeLeft rounds up and never says 0', () {
      expect(AuthorActionsCard.formatTimeLeft(const Duration(minutes: 12, seconds: 10)), '13 min');
      expect(AuthorActionsCard.formatTimeLeft(const Duration(seconds: 40)), 'menos de 1 min');
      expect(AuthorActionsCard.formatTimeLeft(const Duration(minutes: 30)), '30 min');
    });
  });
}

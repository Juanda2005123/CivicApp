import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_event.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_state.dart';
import 'package:vigia_app/features/explore/ui/pages/feed_page.dart';
import 'package:vigia_app/features/explore/ui/widgets/feed_incident_card.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_city_feed_usecase.dart';

import '../../support/fakes.dart';

const _cali = City(
  id: 1,
  name: 'Cali',
  department: 'Valle del Cauca',
  latitude: 3.4516,
  longitude: -76.5320,
  isCapital: true,
);

List<FeedIncident> _reports(int count, {String prefix = 'Reporte'}) => [
      for (var i = 0; i < count; i++)
        FeedIncident(
          id: 'inc-$i',
          trackingCode: '#VIG-${1000 + i}',
          title: '$prefix $i',
          neighborhood: 'Centro',
          categoryName: 'Hueco o bache en calzada',
          categoryIcon: 'warning',
          severity: IncidentSeverity.medium,
          status: IncidentStatus.reported,
          coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
          createdAt: DateTime.utc(2026, 11, 14, 12).subtract(Duration(minutes: i)),
        ),
    ];

void main() {
  late FakeIncidentRepository incidents;
  late FeedBloc bloc;
  late int reportTaps;
  late List<Object?> openedReports;

  Future<void> pumpPage(
    WidgetTester tester, {
    bool withCity = true,
    Coordinates? myLocation,

    // The dotted spinner never stops animating, so a page that shows it cannot settle.
    bool settle = true,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    bloc = FeedBloc(GetCityFeedUseCase(incidents));
    addTearDown(bloc.close);
    if (withCity) bloc.add(FeedCityChanged(_cali));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        routes: {
          AppRoutes.reportDetail: (context) {
            openedReports.add(ModalRoute.of(context)!.settings.arguments);
            return const Scaffold(body: Text('Detalle'));
          },
        },
        home: Scaffold(
          body: BlocProvider<FeedBloc>.value(
            value: bloc,
            child: FeedPage(myLocation: myLocation, onReportPressed: () => reportTaps++),
          ),
        ),
      ),
    );
    settle ? await tester.pumpAndSettle() : await tester.pump();
  }

  /// Drags the list up until the bloc has [count] reports (or gives up).
  Future<void> scrollUntilLoaded(WidgetTester tester, int count) async {
    for (var i = 0; i < 40 && bloc.state.items.length < count; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pumpAndSettle();
    }
  }

  setUp(() {
    incidents = FakeIncidentRepository()..feed = _reports(45);
    reportTaps = 0;
    openedReports = [];
  });

  testWidgets('shows the spinner while the map has not resolved the city', (tester) async {
    await pumpPage(tester, withCity: false, settle: false);

    expect(find.bySemanticsLabel('Cargando los reportes'), findsOneWidget);
    expect(incidents.calls, isEmpty);
  });

  testWidgets('shows the active city and the newest reports first', (tester) async {
    await pumpPage(tester);

    expect(find.text('Cali, Valle del Cauca'), findsOneWidget);
    expect(find.text('Reporte 0'), findsOneWidget);
    expect(find.byType(FeedIncidentCard), findsWidgets);
    expect(bloc.state.items, hasLength(20));
  });

  testWidgets('tapping a card opens the detail of that report', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('Reporte 0'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle'), findsOneWidget);
    expect(openedReports, ['inc-0']);
  });

  testWidgets('the card shows the distance when the position is known', (tester) async {
    const myLocation = Coordinates(latitude: 3.4606, longitude: -76.5320);
    await pumpPage(tester, myLocation: myLocation);

    final meters = const Coordinates(latitude: 3.4516, longitude: -76.5320).distanceInMetersTo(myLocation);

    expect(find.text('Centro · a ${FeedIncidentCard.formatDistance(meters)}'), findsWidgets);
  });

  testWidgets('without a position the cards show no distance', (tester) async {
    await pumpPage(tester);

    expect(find.text('Centro'), findsWidgets);
    expect(find.textContaining('Centro · a'), findsNothing);
  });

  testWidgets('a city without reports invites to publish the first one (criterion 6)', (tester) async {
    incidents.feed = [];
    await pumpPage(tester);

    expect(find.text('Aún no hay reportes en Cali'), findsOneWidget);
    expect(find.byType(FeedIncidentCard), findsNothing);

    await tester.tap(find.text('Reportar daño'));

    expect(reportTaps, 1);
  });

  testWidgets('a failed first load shows the error and "Reintentar" loads the page', (tester) async {
    incidents.feedError = Exception('Sin conexión.');
    await pumpPage(tester);

    expect(find.text('No pudimos cargar los reportes'), findsOneWidget);
    expect(find.text('Sin conexión.'), findsOneWidget);

    incidents.feedError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Reporte 0'), findsOneWidget);
    expect(find.text('No pudimos cargar los reportes'), findsNothing);
  });

  testWidgets('scrolling to the end loads the next page, 20 at a time (criterion 2)', (tester) async {
    await pumpPage(tester);

    await scrollUntilLoaded(tester, 40);

    expect(bloc.state.items, hasLength(40));

    await scrollUntilLoaded(tester, 45);

    expect(bloc.state.items, hasLength(45));
    expect(bloc.state.hasMore, isFalse);
  });

  testWidgets('pull-to-refresh reloads the first page', (tester) async {
    await pumpPage(tester);
    incidents.feed = _reports(3, prefix: 'Nuevo');

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1500);
    await tester.pumpAndSettle();

    expect(bloc.state.items, hasLength(3));
    expect(find.text('Nuevo 0'), findsOneWidget);
    expect(find.text('Reporte 0'), findsNothing);
  });

  testWidgets('a failed refresh keeps the list and shows a retry notice (criterion 5)', (tester) async {
    await pumpPage(tester);
    incidents.feedError = Exception('Sin conexión.');

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1500);
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Reporte 0'), findsOneWidget);

    incidents.feedError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión.'), findsNothing);
    expect(bloc.state.status, FeedStatus.success);
  });

  testWidgets('a failed page offers "Reintentar" and scrolling does not ask again', (tester) async {
    await pumpPage(tester);
    incidents.feedError = Exception('Sin conexión.');

    await scrollUntilLoaded(tester, 40);
    await tester.pumpAndSettle();

    expect(bloc.state.loadMoreFailed, isTrue);
    final callsAfterFailure = incidents.calls.where((c) => c == 'incident.getCityFeed').length;

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(incidents.calls.where((c) => c == 'incident.getCityFeed').length, callsAfterFailure);
    expect(find.text('Reintentar'), findsOneWidget);

    incidents.feedError = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(bloc.state.items, hasLength(40));
    expect(bloc.state.loadMoreFailed, isFalse);
  });

  testWidgets('the page draws in the dark theme and with text at 200 %', (tester) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bloc = FeedBloc(GetCityFeedUseCase(incidents))..add(FeedCityChanged(_cali));
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: BlocProvider<FeedBloc>.value(
              value: bloc,
              child: FeedPage(onReportPressed: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Reporte 0'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/widgets/city/city_hero.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_event.dart';
import 'package:vigia_app/features/explore/ui/pages/feed_page.dart';
import 'package:vigia_app/features/explore/ui/widgets/feed_filter_bar.dart';
import 'package:vigia_app/features/explore/ui/widgets/feed_incident_card.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_city_feed_usecase.dart';

import '../../support/city_theme_host.dart';
import '../../support/fakes.dart';

const _cali = City(
  id: 1,
  name: 'Cali',
  department: 'Valle del Cauca',
  latitude: 3.4516,
  longitude: -76.5320,
  isCapital: true,
);

List<FeedIncident> _reports(int count) => [
      for (var i = 0; i < count; i++)
        FeedIncident(
          id: 'inc-$i',
          trackingCode: '#VIG-${1000 + i}',
          title: 'Reporte $i',
          neighborhood: 'Centro',
          categoryName: 'Hueco',
          categoryIcon: 'warning',
          severity: IncidentSeverity.high,
          status: IncidentStatus.reported,
          coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
          createdAt: DateTime.utc(2026, 11, 14, 12).subtract(Duration(minutes: i)),
        ),
    ];

/// Comunidad in a city with photos: the header opens the list.
void main() {
  late FakeIncidentRepository incidents;

  Future<void> pumpFeed(WidgetTester tester, {Brightness brightness = Brightness.light}) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final bloc = FeedBloc(GetCityFeedUseCase(incidents))..add(FeedCityChanged(_cali));
    addTearDown(bloc.close);

    await tester.pumpWidget(cityHost(
      BlocProvider<FeedBloc>.value(value: bloc, child: FeedPage(onReportPressed: () {})),
      city: 'Cali',
      brightness: brightness,
    ));
    // The header's zoom never ends, so the page cannot "settle".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  setUp(() => incidents = FakeIncidentRepository()..feed = _reports(8));

  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name}: the header greets above the filters and the reports', (tester) async {
      await pumpFeed(tester, brightness: brightness);

      expect(find.text('¡Qué más, ve!'), findsOneWidget);
      expect(find.byType(FeedFilterBar), findsOneWidget);
      expect(find.byType(FeedIncidentCard), findsWidgets);
      final header = tester.getBottomLeft(find.byType(CityHero)).dy;
      expect(tester.getTopLeft(find.byType(FeedFilterBar)).dy, greaterThanOrEqualTo(header));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('scrolling takes the header away, pins the filters and rests the zoom', (tester) async {
    await pumpFeed(tester);
    expect(tester.hasRunningAnimations, isTrue);
    final top = tester.getTopLeft(find.byType(CityHero)).dy;

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
    await tester.pump(const Duration(seconds: 2));

    expect(tester.getTopLeft(find.byType(FeedFilterBar)).dy, top);
    expect(find.text('¡Qué más, ve!').hitTestable(), findsNothing);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('searching keeps working under the header', (tester) async {
    await pumpFeed(tester);

    await tester.enterText(find.byType(TextField), 'Reporte 3');
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(FeedIncidentCard), findsOneWidget);
    expect(find.text('1 reporte coincide'), findsOneWidget);
  });

  testWidgets('a city without reports shows the invitation under its header', (tester) async {
    incidents.feed = [];
    await pumpFeed(tester);

    expect(find.byType(CityHero), findsOneWidget);
    expect(find.text('Aún no hay reportes en Cali'), findsOneWidget);
    expect(find.byType(FeedFilterBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

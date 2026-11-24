import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/explore/domain/entities/report_sort.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_event.dart';
import 'package:vigia_app/features/explore/ui/pages/feed_page.dart';
import 'package:vigia_app/features/explore/ui/widgets/feed_incident_card.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_city_feed_usecase.dart';

import '../../support/fakes.dart';
import '../../support/report_filter_samples.dart';

const _cali = City(
  id: 1,
  name: 'Cali',
  department: 'Valle del Cauca',
  latitude: 3.4516,
  longitude: -76.5320,
  isCapital: true,
);

/// 25 reports (two pages). Every fifth one is a traffic light in Granada; the
/// others are potholes in San Fernando. Report `i` has `i` endorsements, and the
/// higher `i` is, the older and the farther north of the citizen it is.
List<FeedIncident> _reports() => [
      for (var i = 0; i < 25; i++)
        filterFeedIncident(
          id: 'inc-$i',
          code: '#VIG-${1000 + i}',
          title: i % 5 == 0 ? 'Semáforo apagado $i' : 'Hueco número $i',
          description: i % 5 == 0 ? 'Lleva días sin funcionar.' : 'Cráter en la vía.',
          address: i % 5 == 0 ? 'Avenida Sexta # $i' : 'Calle 5 # $i',
          neighborhood: i % 5 == 0 ? 'Granada' : 'San Fernando',
          category: i % 5 == 0 ? 'Semáforo dañado o apagado' : 'Hueco o bache en calzada',
          upvotes: i,
          createdAt: DateTime.utc(2026, 11, 14, 12).subtract(Duration(minutes: i)),
          coordinates: Coordinates(latitude: 3.4516 + i * 0.001, longitude: -76.5320),
        ),
    ];

void main() {
  late FakeIncidentRepository incidents;
  late FeedBloc bloc;

  Future<void> pumpPage(
    WidgetTester tester, {
    Coordinates? myLocation,
    Future<bool> Function()? onLocationNeeded,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    bloc = FeedBloc(GetCityFeedUseCase(incidents))..add(FeedCityChanged(_cali));
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: BlocProvider<FeedBloc>.value(
            value: bloc,
            child: FeedPage(
              myLocation: myLocation,
              onReportPressed: () {},
              onLocationNeeded: onLocationNeeded,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The ids of the cards on screen, top to bottom.
  List<String> shownIds(WidgetTester tester) =>
      tester.widgetList<FeedIncidentCard>(find.byType(FeedIncidentCard)).map((card) => card.incident.id).toList();

  setUp(() => incidents = FakeIncidentRepository()..feed = _reports());

  group('Comunidad search and filters (HU-20)', () {
    testWidgets('shows the search bar, the three chips and the city (criterion 7)', (tester) async {
      await pumpPage(tester);

      expect(find.text('Cali, Valle del Cauca'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar por título, descripción o dirección'), findsOneWidget);
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Barrio'), findsOneWidget);
      expect(find.text('Más recientes'), findsOneWidget);
    });

    testWidgets('the city stays on screen while searching (criterion 7)', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField), 'semaforo');
      await tester.pumpAndSettle();

      expect(find.text('Cali, Valle del Cauca'), findsOneWidget);
    });

    testWidgets('typing filters by title, ignoring accents and case, across every page (criterion 1)', (tester) async {
      await pumpPage(tester);
      expect(bloc.state.items, hasLength(20), reason: 'only the first page before searching');

      await tester.enterText(find.byType(TextField), 'SEMAFORO');
      await tester.pumpAndSettle();

      // 0, 5, 10, 15 and 20: the last one is on the second page.
      expect(shownIds(tester), ['inc-0', 'inc-5', 'inc-10', 'inc-15', 'inc-20']);
      expect(find.text('5 reportes coinciden'), findsOneWidget);
    });

    testWidgets('matches the description and the address too (criterion 1)', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField), 'dias sin funcionar');
      await tester.pumpAndSettle();
      expect(shownIds(tester).first, 'inc-0');
      expect(shownIds(tester), hasLength(5));

      await tester.enterText(find.byType(TextField), 'avenida sexta 15');
      await tester.pumpAndSettle();
      expect(shownIds(tester), ['inc-15']);
      expect(find.text('1 reporte coincide'), findsOneWidget);
    });

    testWidgets('choosing a category keeps only its reports (criterion 2)', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Categoría'));
      await tester.pumpAndSettle();
      expect(find.text('Todas las categorías'), findsOneWidget);
      expect(find.text('Hueco o bache en calzada'), findsOneWidget);

      await tester.tap(find.text('Semáforo dañado o apagado'));
      await tester.pumpAndSettle();

      expect(shownIds(tester), ['inc-0', 'inc-5', 'inc-10', 'inc-15', 'inc-20']);
      // The chip now says which category is on.
      expect(find.text('Semáforo dañado o apagado'), findsOneWidget);
      expect(find.text('Categoría'), findsNothing);
    });

    testWidgets('choosing a neighborhood keeps only its reports (criterion 2)', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Barrio'));
      await tester.pumpAndSettle();
      expect(find.text('Todos los barrios'), findsOneWidget);
      // "Granada" is also on the cards: tap the one in the sheet.
      await tester.tap(find.descendant(of: find.byType(ListTile), matching: find.text('Granada')));
      await tester.pumpAndSettle();

      expect(shownIds(tester), hasLength(5));
      expect(bloc.state.filter.neighborhood, 'Granada');
    });

    testWidgets('"Todas las categorías" takes the category filter off', (tester) async {
      await pumpPage(tester);
      bloc.add(FeedCategorySelected('Semáforo dañado o apagado'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Semáforo dañado o apagado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Todas las categorías'));
      await tester.pumpAndSettle();

      expect(bloc.state.filter.categoryName, isNull);
      expect(find.text('Categoría'), findsOneWidget);
    });
  });

  group('Comunidad order (HU-20, criteria 3 and 4)', () {
    testWidgets('"Más votados" puts the report with the most endorsements first (criterion 3)', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Más recientes'));
      await tester.pumpAndSettle();
      expect(find.text('Ordenar por'), findsOneWidget);
      await tester.tap(find.text('Más votados'));
      await tester.pumpAndSettle();

      expect(shownIds(tester).take(3), ['inc-24', 'inc-23', 'inc-22']);
      expect(find.text('Más votados'), findsOneWidget, reason: 'the chip names the order');
    });

    testWidgets('"Más cercanos" puts the closest first when the position is known (criterion 3)', (tester) async {
      // At the same longitude, the report 0 is the closest to this position.
      await pumpPage(tester, myLocation: const Coordinates(latitude: 3.4516, longitude: -76.5320));

      await tester.tap(find.text('Más recientes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Más cercanos'));
      await tester.pumpAndSettle();

      expect(bloc.state.filter.sort, ReportSort.nearest);
      expect(shownIds(tester).take(3), ['inc-0', 'inc-1', 'inc-2']);
    });

    testWidgets('without a position it asks the shell to locate the citizen and orders when it works', (tester) async {
      var asked = 0;
      await pumpPage(tester, onLocationNeeded: () async {
        asked++;
        return true;
      });

      await tester.tap(find.text('Más recientes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Más cercanos'));
      await tester.pumpAndSettle();

      expect(asked, 1);
      expect(bloc.state.filter.sort, ReportSort.nearest);
    });

    testWidgets('when the location cannot be had it says so and keeps the previous order (criterion 4)',
        (tester) async {
      await pumpPage(tester, onLocationNeeded: () async => false);
      final before = shownIds(tester);

      await tester.tap(find.text('Más recientes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Más cercanos'));
      await tester.pumpAndSettle();

      expect(find.textContaining('activa tu ubicación'), findsOneWidget);
      expect(bloc.state.filter.sort, ReportSort.newest);
      expect(find.text('Más recientes'), findsOneWidget);
      expect(shownIds(tester), before);
    });

    testWidgets('without a callback "Más cercanos" is refused the same way', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('Más recientes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Más cercanos'));
      await tester.pumpAndSettle();

      expect(find.textContaining('activa tu ubicación'), findsOneWidget);
      expect(bloc.state.filter.sort, ReportSort.newest);
    });
  });

  group('Comunidad with no match (HU-20, criterion 6)', () {
    testWidgets('says nothing matches and "Limpiar filtros" brings the list back with one tap', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField), 'zzz nada');
      await tester.pumpAndSettle();

      expect(find.text('Ningún reporte coincide'), findsOneWidget);
      expect(find.byType(FeedIncidentCard), findsNothing);

      // The button in the empty state and the one under the search bar do the same.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Limpiar filtros'));
      await tester.pumpAndSettle();

      expect(find.text('Ningún reporte coincide'), findsNothing);
      expect(shownIds(tester), isNotEmpty);
      expect(bloc.state.filter.isActive, isFalse);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, isEmpty);
    });

    testWidgets('"Limpiar filtros" under the search bar clears the text, the category and the neighborhood',
        (tester) async {
      await pumpPage(tester);
      bloc
        ..add(FeedSearchChanged('hueco'))
        ..add(FeedNeighborhoodSelected('San Fernando'))
        ..add(FeedCategorySelected('Hueco o bache en calzada'));
      await tester.pumpAndSettle();
      expect(find.text('Limpiar filtros'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Limpiar filtros'));
      await tester.pumpAndSettle();

      expect(bloc.state.filter.isActive, isFalse);
      expect(find.text('Limpiar filtros'), findsNothing);
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Barrio'), findsOneWidget);
    });

    testWidgets('the clear button of the search field empties it', (tester) async {
      await pumpPage(tester);

      await tester.enterText(find.byType(TextField), 'hueco');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Borrar búsqueda'));
      await tester.pumpAndSettle();

      expect(bloc.state.filter.query, isEmpty);
    });

    testWidgets('a city with no reports has no search bar, only the invitation', (tester) async {
      incidents.feed = [];
      await pumpPage(tester);

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Aún no hay reportes en Cali'), findsOneWidget);
    });
  });
}

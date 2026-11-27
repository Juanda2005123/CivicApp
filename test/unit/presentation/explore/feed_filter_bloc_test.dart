import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/explore/domain/entities/report_sort.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_event.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_state.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_city_feed_usecase.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/fakes.dart';
import '../../../support/report_filter_samples.dart';

const _cali = City(
  id: 1,
  name: 'Cali',
  department: 'Valle del Cauca',
  latitude: 3.4516,
  longitude: -76.5320,
  isCapital: true,
);
const _pasto = City(
  id: 2,
  name: 'Pasto',
  department: 'Nariño',
  latitude: 1.2136,
  longitude: -77.2811,
  isCapital: true,
);

/// [count] reports, newest first; every third one is in Granada and a traffic light.
List<FeedIncident> _reports(int count, {String prefix = 'inc'}) => [
      for (var i = 0; i < count; i++)
        filterFeedIncident(
          id: '$prefix-$i',
          code: '#VIG-${1000 + i}',
          title: i % 3 == 0 ? 'Semáforo apagado $i' : 'Hueco $i',
          neighborhood: i % 3 == 0 ? 'Granada' : 'San Fernando',
          category: i % 3 == 0 ? 'Semáforo dañado o apagado' : 'Hueco o bache en calzada',
          upvotes: i,
          createdAt: DateTime.utc(2026, 11, 14, 10).subtract(Duration(minutes: i)),
        ),
    ];

void main() {
  late FakeIncidentRepository incidents;

  FeedBloc buildBloc() {
    final bloc = FeedBloc(GetCityFeedUseCase(incidents));
    addTearDown(bloc.close);
    return bloc;
  }

  int pagesAsked() => incidents.calls.where((c) => c == 'incident.getCityFeed').length;

  /// A bloc already showing the first page of Cali (45 reports: 3 pages).
  Future<FeedBloc> openCali() async {
    final bloc = buildBloc();
    bloc.add(FeedCityChanged(_cali));
    await pumpEventQueue();
    return bloc;
  }

  setUp(() => incidents = FakeIncidentRepository()..feed = _reports(45));

  group('FeedBloc filters (HU-20)', () {
    test('starts with no filter and the newest order', () {
      final filter = buildBloc().state.filter;

      expect(filter.isActive, isFalse);
      expect(filter.sort, ReportSort.newest);
    });

    test('typing a search keeps it in the state and loads the rest of the city', () async {
      final bloc = await openCali();
      expect(bloc.state.items, hasLength(20));

      await emittedStates(bloc, FeedSearchChanged('semáforo'));

      expect(bloc.state.filter.query, 'semáforo');
      expect(bloc.state.items, hasLength(45));
      expect(bloc.state.hasMore, isFalse);
      expect(bloc.state.isLoadingMore, isFalse);
      expect(pagesAsked(), 3);
    });

    test('with no filter and the newest order no extra page is asked', () async {
      final bloc = await openCali();

      await emittedStates(bloc, FeedSearchChanged('   '));

      expect(bloc.state.items, hasLength(20));
      expect(pagesAsked(), 1);
    });

    test('the same filter again does nothing', () async {
      final bloc = await openCali();
      await emittedStates(bloc, FeedSearchChanged('hueco'));

      final states = await emittedStates(bloc, FeedSearchChanged('hueco'));

      expect(states, isEmpty);
    });

    test('a category and a neighborhood are kept and can be taken off', () async {
      final bloc = await openCali();

      await emittedStates(bloc, FeedCategorySelected('Semáforo dañado o apagado'));
      await emittedStates(bloc, FeedNeighborhoodSelected('Granada'));
      expect(bloc.state.filter.categoryName, 'Semáforo dañado o apagado');
      expect(bloc.state.filter.neighborhood, 'Granada');

      await emittedStates(bloc, FeedCategorySelected(null));
      expect(bloc.state.filter.categoryName, isNull);
      expect(bloc.state.filter.neighborhood, 'Granada');

      await emittedStates(bloc, FeedNeighborhoodSelected(null));
      expect(bloc.state.filter.isActive, isFalse);
    });

    test('choosing an order other than the newest loads the whole city', () async {
      final bloc = await openCali();

      await emittedStates(bloc, FeedSortSelected(ReportSort.mostEndorsed));

      expect(bloc.state.filter.sort, ReportSort.mostEndorsed);
      expect(bloc.state.items, hasLength(45));
    });

    test('"Limpiar filtros" takes the filters off and keeps the order', () async {
      final bloc = await openCali();
      await emittedStates(bloc, FeedSortSelected(ReportSort.mostEndorsed));
      await emittedStates(bloc, FeedSearchChanged('hueco'));
      await emittedStates(bloc, FeedCategorySelected('Hueco o bache en calzada'));

      await emittedStates(bloc, FeedFiltersCleared());

      expect(bloc.state.filter.isActive, isFalse);
      expect(bloc.state.filter.sort, ReportSort.mostEndorsed);
    });

    test('the filter narrows what the screens draw, not what is loaded', () async {
      final bloc = await openCali();
      await emittedStates(bloc, FeedCategorySelected('Semáforo dañado o apagado'));

      final visible = bloc.state.filter.applyToFeed(bloc.state.items);

      expect(bloc.state.items, hasLength(45));
      expect(visible, hasLength(15));
      expect(visible.every((i) => i.categoryName == 'Semáforo dañado o apagado'), isTrue);
    });

    test('a new city starts without the filters of the previous one', () async {
      final bloc = await openCali();
      await emittedStates(bloc, FeedNeighborhoodSelected('Granada'));
      incidents.feed = _reports(3, prefix: 'pasto');

      await emittedStates(bloc, FeedCityChanged(_pasto));

      expect(bloc.state.filter.isActive, isFalse);
      expect(bloc.state.filter.sort, ReportSort.newest);
    });

    test('a refresh keeps the filter and brings the whole city back', () async {
      final bloc = await openCali();
      await emittedStates(bloc, FeedSearchChanged('hueco'));
      expect(bloc.state.items, hasLength(45));

      await emittedStates(bloc, FeedRefreshed());

      expect(bloc.state.filter.query, 'hueco');
      expect(bloc.state.items, hasLength(45));
      expect(bloc.state.status, FeedStatus.success);
    });

    test('a page that fails stops the loading, keeps the filter and offers a retry', () async {
      final bloc = await openCali();
      incidents.feedError = Exception('Sin conexión');

      await emittedStates(bloc, FeedSearchChanged('hueco'));

      expect(bloc.state.filter.query, 'hueco');
      expect(bloc.state.items, hasLength(20), reason: 'the first page stays');
      expect(bloc.state.loadMoreFailed, isTrue);
      expect(bloc.state.isLoadingMore, isFalse);
      expect(bloc.state.errorMessage, 'Sin conexión');
    });

    test('FeedAllPagesRequested loads the rest with no filter at all', () async {
      final bloc = await openCali();

      await emittedStates(bloc, FeedAllPagesRequested());

      expect(bloc.state.items, hasLength(45));
      expect(bloc.state.filter.isActive, isFalse);
    });

    test('it stops at the limit of reports it filters', () async {
      incidents.feed = _reports(250);
      final bloc = await openCali();

      await emittedStates(bloc, FeedSearchChanged('hueco'));

      expect(bloc.state.items, hasLength(FeedBloc.maxFilterableItems));
      expect(bloc.state.hasMore, isTrue);
      expect(bloc.state.isLoadingMore, isFalse);
    });
  });
}

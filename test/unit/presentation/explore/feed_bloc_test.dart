import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_event.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_state.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_city_feed_usecase.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/fakes.dart';

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

List<FeedIncident> _reports(int count, {String prefix = 'inc'}) => [
      for (var i = 0; i < count; i++)
        FeedIncident(
          id: '$prefix-$i',
          trackingCode: '#VIG-${1000 + i}',
          title: 'Reporte $i',
          neighborhood: 'Centro',
          categoryName: 'Hueco o bache en calzada',
          categoryIcon: 'warning',
          severity: IncidentSeverity.medium,
          status: IncidentStatus.reported,
          coordinates: const Coordinates(latitude: 3.45, longitude: -76.53),
          createdAt: DateTime.utc(2026, 11, 14, 10).subtract(Duration(minutes: i)),
        ),
    ];

/// Holds the answer of a city until the test releases it, to observe a request
/// that is still in flight.
class _GatedIncidentRepository extends FakeIncidentRepository {
  final Map<String, Completer<void>> gates = {};
  final Map<String, List<FeedIncident>> feeds = {};

  @override
  Future<List<FeedIncident>> getCityFeed(String city, {required int offset, int limit = 20}) async {
    final gate = gates[city];
    if (gate != null) await gate.future;
    return (feeds[city] ?? const <FeedIncident>[]).skip(offset).take(limit).toList();
  }
}

void main() {
  late FakeIncidentRepository incidents;

  FeedBloc buildBloc([FakeIncidentRepository? repository]) {
    final bloc = FeedBloc(GetCityFeedUseCase(repository ?? incidents));
    addTearDown(bloc.close);
    return bloc;
  }

  setUp(() {
    incidents = FakeIncidentRepository()..feed = _reports(45);
  });

  test('starts empty, without a city', () {
    final bloc = buildBloc();

    expect(bloc.state.status, FeedStatus.initial);
    expect(bloc.state.city, isNull);
    expect(bloc.state.items, isEmpty);
    expect(bloc.state.hasMore, isFalse);
  });

  group('FeedCityChanged', () {
    test('emits loading with the city and then its first page', () async {
      final states = await emittedStates(buildBloc(), FeedCityChanged(_cali));

      expect(states.map((s) => s.status), [FeedStatus.loading, FeedStatus.success]);
      expect(states.first.city, _cali);
      expect(states.first.items, isEmpty);
      expect(states.last.items, hasLength(20));
      expect(states.last.hasMore, isTrue);
      expect(incidents.lastCity, 'Cali');
    });

    test('the same city again does nothing', () async {
      final bloc = buildBloc();
      await emittedStates(bloc, FeedCityChanged(_cali));

      final states = await emittedStates(bloc, FeedCityChanged(_cali));

      expect(states, isEmpty);
      expect(incidents.calls.where((c) => c == 'incident.getCityFeed'), hasLength(1));
    });

    test('another city replaces the list, nothing of the first one stays', () async {
      final bloc = buildBloc();
      await emittedStates(bloc, FeedCityChanged(_cali));
      incidents.feed = _reports(3, prefix: 'pasto');

      final states = await emittedStates(bloc, FeedCityChanged(_pasto));

      expect(states.first.items, isEmpty);
      expect(states.first.city, _pasto);
      expect(states.last.items.map((i) => i.id), ['pasto-0', 'pasto-1', 'pasto-2']);
      expect(states.last.hasMore, isFalse);
    });

    test('a city without reports ends on an empty success', () async {
      incidents.feed = [];

      final states = await emittedStates(buildBloc(), FeedCityChanged(_cali));

      expect(states.last.status, FeedStatus.success);
      expect(states.last.items, isEmpty);
    });

    test('a failure on the first load says why and leaves no list', () async {
      incidents.feedError = Exception('No pudimos cargar los reportes de la comunidad.');

      final states = await emittedStates(buildBloc(), FeedCityChanged(_cali));

      expect(states.last.status, FeedStatus.failure);
      expect(states.last.errorMessage, 'No pudimos cargar los reportes de la comunidad.');
      expect(states.last.items, isEmpty);
    });

    test('the late answer of the previous city is dropped', () async {
      final gated = _GatedIncidentRepository()
        ..feeds['Cali'] = _reports(5, prefix: 'cali')
        ..feeds['Pasto'] = _reports(2, prefix: 'pasto')
        ..gates['Cali'] = Completer<void>();
      final bloc = buildBloc(gated);

      bloc.add(FeedCityChanged(_cali));
      await pumpEventQueue();
      bloc.add(FeedCityChanged(_pasto));
      await pumpEventQueue();
      gated.gates['Cali']!.complete();
      await pumpEventQueue();

      expect(bloc.state.city, _pasto);
      expect(bloc.state.items.map((i) => i.id), ['pasto-0', 'pasto-1']);
    });
  });

  group('FeedRefreshed', () {
    test('keeps the list on screen while it loads and then replaces it', () async {
      final bloc = buildBloc();
      await emittedStates(bloc, FeedCityChanged(_cali));
      incidents.feed = _reports(2, prefix: 'new');

      final states = await emittedStates(bloc, FeedRefreshed());

      expect(states.map((s) => s.status), [FeedStatus.loading, FeedStatus.success]);
      expect(states.first.items, hasLength(20));
      expect(states.last.items.map((i) => i.id), ['new-0', 'new-1']);
      expect(states.last.hasMore, isFalse);
    });

    test('a failed refresh keeps the old list and says why', () async {
      final bloc = buildBloc();
      await emittedStates(bloc, FeedCityChanged(_cali));
      incidents.feedError = Exception('Sin conexión.');

      final states = await emittedStates(bloc, FeedRefreshed());

      expect(states.last.status, FeedStatus.failure);
      expect(states.last.errorMessage, 'Sin conexión.');
      expect(states.last.items, hasLength(20));
    });

    test('retrying after a failed first load loads the page', () async {
      incidents.feedError = Exception('Sin conexión.');
      final bloc = buildBloc();
      await emittedStates(bloc, FeedCityChanged(_cali));
      incidents.feedError = null;

      final states = await emittedStates(bloc, FeedRefreshed());

      expect(states.last.status, FeedStatus.success);
      expect(states.last.errorMessage, isNull);
      expect(states.last.items, hasLength(20));
    });

    test('without a city there is nothing to refresh', () async {
      final states = await emittedStates(buildBloc(), FeedRefreshed());

      expect(states, isEmpty);
      expect(incidents.calls, isEmpty);
    });
  });

  group('FeedNextPageRequested', () {
    test('appends the next page after the ones already shown', () async {
      final bloc = buildBloc();
      await emittedStates(bloc, FeedCityChanged(_cali));

      final states = await emittedStates(bloc, FeedNextPageRequested());

      expect(states.first.isLoadingMore, isTrue);
      expect(states.first.items, hasLength(20));
      expect(states.last.isLoadingMore, isFalse);
      expect(states.last.items, hasLength(40));
      expect(states.last.items[20].id, 'inc-20');
      expect(states.last.hasMore, isTrue);
    });

    test('the last page turns hasMore off and later requests do nothing', () async {
      final bloc = buildBloc();
      await emittedStates(bloc, FeedCityChanged(_cali));
      await emittedStates(bloc, FeedNextPageRequested());
      final states = await emittedStates(bloc, FeedNextPageRequested());

      expect(states.last.items, hasLength(45));
      expect(states.last.hasMore, isFalse);

      final more = await emittedStates(bloc, FeedNextPageRequested());

      expect(more, isEmpty);
    });

    test('a failed page keeps the list and flags the retry; retrying works', () async {
      final bloc = buildBloc();
      await emittedStates(bloc, FeedCityChanged(_cali));
      incidents.feedError = Exception('Sin conexión.');

      final failed = await emittedStates(bloc, FeedNextPageRequested());

      expect(failed.last.status, FeedStatus.success);
      expect(failed.last.loadMoreFailed, isTrue);
      expect(failed.last.errorMessage, 'Sin conexión.');
      expect(failed.last.items, hasLength(20));
      expect(failed.last.hasMore, isTrue);

      incidents.feedError = null;
      final retried = await emittedStates(bloc, FeedNextPageRequested());

      expect(retried.last.loadMoreFailed, isFalse);
      expect(retried.last.errorMessage, isNull);
      expect(retried.last.items, hasLength(40));
    });

    test('a second request while one is loading is ignored', () async {
      final gated = _GatedIncidentRepository()..feeds['Cali'] = _reports(45);
      final bloc = buildBloc(gated);
      await emittedStates(bloc, FeedCityChanged(_cali));
      gated.gates['Cali'] = Completer<void>();

      bloc
        ..add(FeedNextPageRequested())
        ..add(FeedNextPageRequested());
      await pumpEventQueue();
      gated.gates['Cali']!.complete();
      await pumpEventQueue();

      expect(bloc.state.items, hasLength(40));
    });

    test('without a loaded first page there is nothing to append to', () async {
      final states = await emittedStates(buildBloc(), FeedNextPageRequested());

      expect(states, isEmpty);
    });

    test('a refresh while the next page loads is ignored, so the page is not lost', () async {
      final gated = _GatedIncidentRepository()..feeds['Cali'] = _reports(45);
      final bloc = buildBloc(gated);
      await emittedStates(bloc, FeedCityChanged(_cali));
      gated.gates['Cali'] = Completer<void>();

      bloc.add(FeedNextPageRequested());
      await pumpEventQueue();
      bloc.add(FeedRefreshed());
      await pumpEventQueue();

      expect(bloc.state.status, FeedStatus.success);
      expect(bloc.state.isLoadingMore, isTrue);

      gated.gates['Cali']!.complete();
      await pumpEventQueue();

      expect(bloc.state.items, hasLength(40));
      expect(bloc.state.isLoadingMore, isFalse);
    });
  });
}

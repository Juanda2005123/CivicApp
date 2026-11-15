import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_city_feed_usecase.dart';

import '../../../support/fakes.dart';

List<FeedIncident> _reports(int count) => [
      for (var i = 0; i < count; i++)
        FeedIncident(
          id: 'inc-$i',
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

void main() {
  late FakeIncidentRepository incidents;
  late GetCityFeedUseCase useCase;

  setUp(() {
    incidents = FakeIncidentRepository();
    useCase = GetCityFeedUseCase(incidents);
  });

  test('a full page says there may be more', () async {
    incidents.feed = _reports(45);

    final (items, hasMore) = await useCase('Cali');

    expect(items, hasLength(GetCityFeedUseCase.pageSize));
    expect(items.first.id, 'inc-0');
    expect(hasMore, isTrue);
    expect(incidents.lastCity, 'Cali');
  });

  test('the next page starts where the previous one ended', () async {
    incidents.feed = _reports(45);

    final (items, hasMore) = await useCase('Cali', offset: 20);

    expect(items.first.id, 'inc-20');
    expect(items, hasLength(20));
    expect(hasMore, isTrue);
  });

  test('a short page is the last one', () async {
    incidents.feed = _reports(45);

    final (items, hasMore) = await useCase('Cali', offset: 40);

    expect(items, hasLength(5));
    expect(hasMore, isFalse);
  });

  test('a city with exactly one page answers more once, then comes back empty', () async {
    incidents.feed = _reports(20);

    final (_, firstHasMore) = await useCase('Cali');
    final (next, nextHasMore) = await useCase('Cali', offset: 20);

    expect(firstHasMore, isTrue);
    expect(next, isEmpty);
    expect(nextHasMore, isFalse);
  });

  test('a city without reports answers an empty page', () async {
    final (items, hasMore) = await useCase('Cali');

    expect(items, isEmpty);
    expect(hasMore, isFalse);
  });

  test('a blank city is rejected before asking the repository', () async {
    await expectLater(
      useCase('  '),
      throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Elige una ciudad'))),
    );
    expect(incidents.calls, isEmpty);
  });

  test('a negative offset is rejected before asking the repository', () async {
    await expectLater(useCase('Cali', offset: -1), throwsException);
    expect(incidents.calls, isEmpty);
  });

  test('the repository failure reaches the caller untouched', () async {
    incidents.feedError = Exception('No pudimos cargar los reportes de la comunidad.');

    await expectLater(
      useCase('Cali'),
      throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('reportes de la comunidad'))),
    );
  });
}

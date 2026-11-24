import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/explore/domain/entities/feed_filter_options.dart';
import 'package:vigia_app/features/explore/domain/entities/report_filter.dart';
import 'package:vigia_app/features/explore/domain/entities/report_sort.dart';

import '../../../support/report_filter_samples.dart';

void main() {
  group('ReportFilter search (HU-20, criterion 1)', () {
    final items = [
      filterFeedIncident(id: 'a', title: 'Hueco profundo', description: 'Cráter en el carril derecho.'),
      filterFeedIncident(
        id: 'b',
        code: '#VIG-2002',
        title: 'Semáforo apagado',
        description: 'Lleva dos días sin funcionar.',
        address: 'Avenida Sexta # 20-10',
        neighborhood: 'Granada',
        category: 'Semáforo dañado o apagado',
      ),
    ];

    List<String> ids(ReportFilter filter) => filter.applyToFeed(items).map((i) => i.id).toList();

    test('no text and no filter keeps every report in the original order', () {
      expect(ids(const ReportFilter()), ['a', 'b']);
      expect(const ReportFilter().isActive, isFalse);
    });

    test('matches the title, ignoring case', () {
      expect(ids(const ReportFilter(query: 'SEMÁFORO')), ['b']);
    });

    test('matches the description', () {
      expect(ids(const ReportFilter(query: 'carril derecho')), ['a']);
    });

    test('matches the address', () {
      expect(ids(const ReportFilter(query: 'avenida sexta')), ['b']);
    });

    test('ignores accents on both sides', () {
      expect(ids(const ReportFilter(query: 'semaforo')), ['b']);
      expect(ids(const ReportFilter(query: 'crater')), ['a']);
    });

    test('every word has to be there, in any order', () {
      expect(ids(const ReportFilter(query: 'derecho carril')), ['a']);
      expect(ids(const ReportFilter(query: 'derecho semaforo')), isEmpty);
    });

    test('matches the neighborhood and the tracking code too', () {
      expect(ids(const ReportFilter(query: 'granada')), ['b']);
      expect(ids(const ReportFilter(query: '2002')), ['b']);
    });

    test('blank spaces alone are not a search', () {
      expect(const ReportFilter(query: '   ').isActive, isFalse);
      expect(ids(const ReportFilter(query: '   ')), ['a', 'b']);
    });
  });

  group('ReportFilter category and neighborhood (criterion 2)', () {
    final items = [
      filterFeedIncident(id: 'a', neighborhood: 'San Fernando', category: 'Hueco o bache en calzada'),
      filterFeedIncident(id: 'b', neighborhood: 'Granada', category: 'Hueco o bache en calzada'),
      filterFeedIncident(id: 'c', neighborhood: 'Granada', category: 'Semáforo dañado o apagado'),
    ];

    List<String> ids(ReportFilter filter) => filter.applyToFeed(items).map((i) => i.id).toList();

    test('a category keeps only its reports', () {
      expect(ids(const ReportFilter(categoryName: 'Semáforo dañado o apagado')), ['c']);
    });

    test('a neighborhood keeps only its reports, ignoring accents and case', () {
      expect(ids(const ReportFilter(neighborhood: 'GRANADA')), ['b', 'c']);
    });

    test('category and neighborhood together narrow further', () {
      expect(
        ids(const ReportFilter(categoryName: 'Hueco o bache en calzada', neighborhood: 'Granada')),
        ['b'],
      );
    });

    test('they combine with the text', () {
      // All three share the title "Hueco profundo"; the neighborhood narrows it.
      expect(ids(const ReportFilter(query: 'hueco', neighborhood: 'Granada')), ['b', 'c']);
    });

    test('activeCount says how many filters are on and the order does not count', () {
      const filter = ReportFilter(
        query: 'hueco',
        categoryName: 'Hueco o bache en calzada',
        sort: ReportSort.mostEndorsed,
      );

      expect(filter.activeCount, 2);
      expect(const ReportFilter(sort: ReportSort.mostEndorsed).isActive, isFalse);
    });

    test('cleared turns the filters off and keeps the order (criterion 6)', () {
      const filter = ReportFilter(
        query: 'hueco',
        categoryName: 'Hueco o bache en calzada',
        neighborhood: 'Granada',
        sort: ReportSort.mostEndorsed,
      );

      final cleared = filter.cleared();

      expect(cleared.isActive, isFalse);
      expect(cleared.sort, ReportSort.mostEndorsed);
    });

    test('copyWith can clear one filter without touching the others', () {
      const filter = ReportFilter(categoryName: 'Hueco', neighborhood: 'Granada');

      expect(filter.copyWith(clearCategory: true).categoryName, isNull);
      expect(filter.copyWith(clearCategory: true).neighborhood, 'Granada');
    });
  });

  group('ReportFilter order (criterion 3)', () {
    final items = [
      filterFeedIncident(id: 'old-many', upvotes: 8, createdAt: DateTime(2026, 11, 1), coordinates: const Coordinates(latitude: 3.50, longitude: -76.53)),
      filterFeedIncident(id: 'new-few', upvotes: 2, createdAt: DateTime(2026, 11, 20), coordinates: const Coordinates(latitude: 3.46, longitude: -76.53)),
      filterFeedIncident(id: 'mid-many', upvotes: 8, createdAt: DateTime(2026, 11, 10), coordinates: const Coordinates(latitude: 3.4517, longitude: -76.5320)),
    ];
    const me = Coordinates(latitude: 3.4516, longitude: -76.5320);

    List<String> ids(ReportFilter filter, {Coordinates? at}) =>
        filter.applyToFeed(items, myLocation: at).map((i) => i.id).toList();

    test('newest keeps the order the list arrives in', () {
      expect(ids(const ReportFilter()), ['old-many', 'new-few', 'mid-many']);
    });

    test('most endorsed puts the most votes first and the newest breaks a tie', () {
      expect(ids(const ReportFilter(sort: ReportSort.mostEndorsed)), ['mid-many', 'old-many', 'new-few']);
    });

    test('nearest puts the closest first', () {
      expect(ids(const ReportFilter(sort: ReportSort.nearest), at: me), ['mid-many', 'new-few', 'old-many']);
    });

    test('nearest without a position keeps the previous order (criterion 4)', () {
      expect(ids(const ReportFilter(sort: ReportSort.nearest)), ['old-many', 'new-few', 'mid-many']);
    });

    test('the order applies to the filtered list only', () {
      final result = const ReportFilter(query: 'nada que coincida', sort: ReportSort.mostEndorsed).applyToFeed(items);

      expect(result, isEmpty);
    });

    test('labels are the ones the citizen reads', () {
      expect(ReportSort.values.map((s) => s.labelSpanish), ['Más recientes', 'Más votados', 'Más cercanos']);
    });

    test('filters and a non-default order need the whole city, the default list does not', () {
      expect(const ReportFilter().needsFullList, isFalse);
      expect(const ReportFilter(query: 'a').needsFullList, isTrue);
      expect(const ReportFilter(sort: ReportSort.mostEndorsed).needsFullList, isTrue);
    });
  });

  group('ReportFilter on the map (criterion 5)', () {
    final markers = [
      filterMarker(id: 'a', neighborhood: 'San Fernando', category: 'Hueco o bache en calzada'),
      filterMarker(id: 'b', title: 'Semáforo apagado', neighborhood: 'Granada', category: 'Semáforo dañado o apagado'),
    ];

    test('the same filter keeps the matching markers', () {
      expect(const ReportFilter(categoryName: 'Semáforo dañado o apagado').applyToMarkers(markers).map((m) => m.id), ['b']);
      expect(const ReportFilter(neighborhood: 'san fernando').applyToMarkers(markers).map((m) => m.id), ['a']);
      expect(const ReportFilter(query: 'semaforo').applyToMarkers(markers).map((m) => m.id), ['b']);
    });

    test('no filter keeps every marker', () {
      expect(const ReportFilter().applyToMarkers(markers), hasLength(2));
    });
  });

  group('FeedFilterOptions', () {
    test('lists each category and neighborhood once, alphabetically, ignoring accents and blanks', () {
      final options = FeedFilterOptions.fromItems([
        filterFeedIncident(neighborhood: 'San Fernando', category: 'Semáforo dañado o apagado'),
        filterFeedIncident(neighborhood: 'san fernando', category: 'Hueco o bache en calzada'),
        filterFeedIncident(neighborhood: 'Álamos', category: 'Hueco o bache en calzada'),
        filterFeedIncident(neighborhood: '  ', category: 'Hueco o bache en calzada'),
      ]);

      expect(options.categories, ['Hueco o bache en calzada', 'Semáforo dañado o apagado']);
      expect(options.neighborhoods, ['Álamos', 'San Fernando']);
    });

    test('an empty city has no options', () {
      expect(FeedFilterOptions.fromItems(const []), const FeedFilterOptions());
    });
  });
}

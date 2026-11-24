import 'package:equatable/equatable.dart';
import 'package:vigia_app/core/utils/search_text.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_marker.dart';

import 'report_sort.dart';

/// What the citizen asked to see in Comunidad and on the map (HU-20): a text, a
/// category, a neighborhood and an order. The same filter drives both screens
/// (criterion 5); the order only matters to the list.
class ReportFilter extends Equatable {
  /// Words to look for in the title, the description, the address, the
  /// neighborhood and the tracking code, ignoring accents and case. Every word
  /// must appear.
  final String query;
  final String? categoryName;
  final String? neighborhood;
  final ReportSort sort;

  const ReportFilter({
    this.query = '',
    this.categoryName,
    this.neighborhood,
    this.sort = ReportSort.newest,
  });

  /// Something narrows the list. The order alone does not count as a filter.
  bool get isActive => query.trim().isNotEmpty || categoryName != null || neighborhood != null;

  /// How many of the three filters are on, for the "Filtros activos" label.
  int get activeCount =>
      (query.trim().isNotEmpty ? 1 : 0) + (categoryName != null ? 1 : 0) + (neighborhood != null ? 1 : 0);

  /// Filtering and ordering need the whole city, not only the pages already
  /// loaded: otherwise "Más votados" would only rank the first 20.
  bool get needsFullList => isActive || sort != ReportSort.newest;

  ReportFilter copyWith({
    String? query,
    String? categoryName,
    bool clearCategory = false,
    String? neighborhood,
    bool clearNeighborhood = false,
    ReportSort? sort,
  }) {
    return ReportFilter(
      query: query ?? this.query,
      categoryName: clearCategory ? null : (categoryName ?? this.categoryName),
      neighborhood: clearNeighborhood ? null : (neighborhood ?? this.neighborhood),
      sort: sort ?? this.sort,
    );
  }

  /// The same order with no filter on (criterion 6: "Limpiar filtros").
  ReportFilter cleared() => ReportFilter(sort: sort);

  bool matchesFeed(FeedIncident incident) {
    return _matches(
      incident.categoryName,
      incident.neighborhood,
      [incident.title, incident.description, incident.formattedAddress, incident.neighborhood, incident.trackingCode],
    );
  }

  bool matchesMarker(IncidentMarker marker) {
    return _matches(
      marker.categoryName,
      marker.neighborhood,
      [marker.title, marker.description, marker.formattedAddress, marker.neighborhood, marker.trackingCode],
    );
  }

  bool _matches(String category, String neighborhoodOfReport, List<String> searchable) {
    final wantedCategory = categoryName;
    if (wantedCategory != null && normalizeSearchText(category) != normalizeSearchText(wantedCategory)) {
      return false;
    }
    final wantedNeighborhood = neighborhood;
    if (wantedNeighborhood != null &&
        normalizeSearchText(neighborhoodOfReport) != normalizeSearchText(wantedNeighborhood)) {
      return false;
    }
    final words = normalizeSearchText(query).split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    if (words.isEmpty) return true;
    final haystack = normalizeSearchText(searchable.join(' '));
    return words.every(haystack.contains);
  }

  /// The reports that match, in the chosen order. [myLocation] is only needed
  /// for [ReportSort.nearest]; without it that order falls back to the newest.
  List<FeedIncident> applyToFeed(List<FeedIncident> items, {Coordinates? myLocation}) {
    final matching = items.where(matchesFeed).toList();

    int newestFirst(FeedIncident a, FeedIncident b) {
      final byDate = b.createdAt.compareTo(a.createdAt);
      return byDate != 0 ? byDate : b.id.compareTo(a.id);
    }

    switch (sort) {
      case ReportSort.newest:
        return matching;
      case ReportSort.mostEndorsed:
        return matching
          ..sort((a, b) {
            final byVotes = b.upvotesCount.compareTo(a.upvotesCount);
            return byVotes != 0 ? byVotes : newestFirst(a, b);
          });
      case ReportSort.nearest:
        if (myLocation == null) return matching;
        return matching
          ..sort((a, b) {
            final byDistance = a.coordinates
                .distanceInMetersTo(myLocation)
                .compareTo(b.coordinates.distanceInMetersTo(myLocation));
            return byDistance != 0 ? byDistance : newestFirst(a, b);
          });
    }
  }

  List<IncidentMarker> applyToMarkers(List<IncidentMarker> markers) => markers.where(matchesMarker).toList();

  @override
  List<Object?> get props => [query, categoryName, neighborhood, sort];
}

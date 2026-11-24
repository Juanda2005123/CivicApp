import '../../../auth/domain/entities/city.dart';
import '../../domain/entities/report_sort.dart';

abstract class FeedEvent {}

/// The city the feed shows changed (the map resolved it, or the citizen picked
/// another one on the city switcher): load its first page. The same city again
/// does nothing.
class FeedCityChanged extends FeedEvent {
  final City city;

  FeedCityChanged(this.city);
}

/// Pull-to-refresh, or "Reintentar" after a failed first load: reload the first
/// page of the current city.
class FeedRefreshed extends FeedEvent {}

/// The citizen scrolled near the end of the list, or tapped "Reintentar" under
/// it: load the next page.
class FeedNextPageRequested extends FeedEvent {}

/// The citizen typed in the search bar (HU-20). An empty text clears the search.
class FeedSearchChanged extends FeedEvent {
  final String query;

  FeedSearchChanged(this.query);
}

/// The citizen picked a category, or null to take the category filter off (HU-20).
class FeedCategorySelected extends FeedEvent {
  final String? categoryName;

  FeedCategorySelected(this.categoryName);
}

/// The citizen picked a neighborhood, or null to take that filter off (HU-20).
class FeedNeighborhoodSelected extends FeedEvent {
  final String? neighborhood;

  FeedNeighborhoodSelected(this.neighborhood);
}

/// The citizen picked another order (HU-20).
class FeedSortSelected extends FeedEvent {
  final ReportSort sort;

  FeedSortSelected(this.sort);
}

/// "Limpiar filtros": the search, the category and the neighborhood go; the
/// order stays (HU-20, criterion 6).
class FeedFiltersCleared extends FeedEvent {}

/// Load every remaining page of the city, for example when the filter sheet
/// opens: its options come from the reports that are loaded.
class FeedAllPagesRequested extends FeedEvent {}

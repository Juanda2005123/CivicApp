import '../../../auth/domain/entities/city.dart';

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

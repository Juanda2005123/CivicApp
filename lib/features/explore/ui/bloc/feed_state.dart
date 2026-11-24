import '../../../auth/domain/entities/city.dart';
import '../../../reports/domain/entities/feed_incident.dart';
import '../../domain/entities/report_filter.dart';

/// `loading` covers the first page and a refresh; the next page has its own
/// flag so the list stays on screen while it arrives.
enum FeedStatus { initial, loading, success, failure }

/// Single state with a status: a refresh or a failure never wipes the list.
class FeedState {
  final FeedStatus status;
  final City? city;
  final List<FeedIncident> items;

  /// True while the last page loaded was full, so another one may follow.
  final bool hasMore;
  final bool isLoadingMore;

  /// The next page failed: the page shows "Reintentar" under the list instead
  /// of asking again on every scroll.
  final bool loadMoreFailed;
  final String? errorMessage;

  /// What the citizen searched, filtered and ordered by (HU-20). The map reads
  /// it too, so both screens narrow the same way. A new city starts clean.
  final ReportFilter filter;

  const FeedState({
    this.status = FeedStatus.initial,
    this.city,
    this.items = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.errorMessage,
    this.filter = const ReportFilter(),
  });

  /// First load of [city]: loading, with nothing left of the previous city.
  const FeedState.loading(City this.city)
      : status = FeedStatus.loading,
        items = const [],
        hasMore = false,
        isLoadingMore = false,
        loadMoreFailed = false,
        errorMessage = null,
        filter = const ReportFilter();

  FeedState copyWith({
    FeedStatus? status,
    List<FeedIncident>? items,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    String? errorMessage,
    bool clearErrorMessage = false,
    ReportFilter? filter,
  }) {
    return FeedState(
      status: status ?? this.status,
      city: city,
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      filter: filter ?? this.filter,
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../reports/domain/usecases/get_city_feed_usecase.dart';
import '../../domain/entities/report_filter.dart';
import 'feed_event.dart';
import 'feed_state.dart';

/// Loads the community feed of the active city page by page (HU-19).
///
/// An answer that arrives after the citizen moved to another city (or after
/// the list changed under it) is dropped: each handler checks, once its
/// request returns, that the state still is the one it started from.
///
/// It also holds the search, the filters and the order of Comunidad and the map
/// (HU-20). The reports are filtered here, on the device, so filtering and
/// ordering need the whole city: while a filter or an order is on, the remaining
/// pages are loaded too, up to [maxFilterableItems].
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  /// The most reports loaded to filter and order them, the same limit the map has.
  static const int maxFilterableItems = 200;

  final GetCityFeedUseCase _getCityFeed;

  FeedBloc(this._getCityFeed) : super(const FeedState()) {
    on<FeedCityChanged>(_onCityChanged);
    on<FeedRefreshed>(_onRefreshed);
    on<FeedNextPageRequested>(_onNextPageRequested);
    on<FeedSearchChanged>((event, emit) => _applyFilter(state.filter.copyWith(query: event.query), emit));
    on<FeedCategorySelected>((event, emit) {
      final filter = state.filter;
      final category = event.categoryName;
      return _applyFilter(
        category == null ? filter.copyWith(clearCategory: true) : filter.copyWith(categoryName: category),
        emit,
      );
    });
    on<FeedNeighborhoodSelected>((event, emit) {
      final filter = state.filter;
      final neighborhood = event.neighborhood;
      return _applyFilter(
        neighborhood == null ? filter.copyWith(clearNeighborhood: true) : filter.copyWith(neighborhood: neighborhood),
        emit,
      );
    });
    on<FeedSortSelected>((event, emit) => _applyFilter(state.filter.copyWith(sort: event.sort), emit));
    on<FeedFiltersCleared>((event, emit) => _applyFilter(state.filter.cleared(), emit));
    on<FeedAllPagesRequested>((event, emit) => _loadAllPages(emit));
  }

  /// Takes the new filter and, when it needs the whole city, loads what is missing.
  Future<void> _applyFilter(ReportFilter filter, Emitter<FeedState> emit) async {
    if (filter == state.filter) return;
    emit(state.copyWith(filter: filter));
    if (filter.needsFullList) await _loadAllPages(emit);
  }

  /// Pages in a loop until the city is complete or the limit is reached. A failed
  /// page stops it and leaves the "Reintentar" of the list.
  Future<void> _loadAllPages(Emitter<FeedState> emit) async {
    final city = state.city;
    if (city == null || state.status != FeedStatus.success || !state.hasMore || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true, loadMoreFailed: false, clearErrorMessage: true));
    try {
      while (state.hasMore && state.items.length < maxFilterableItems) {
        final offset = state.items.length;
        final (items, hasMore) = await _getCityFeed(city.name, offset: offset);
        if (state.city != city || state.items.length != offset) return;
        emit(state.copyWith(items: [...state.items, ...items], hasMore: hasMore));
      }
      emit(state.copyWith(isLoadingMore: false));
    } on Exception catch (e) {
      if (state.city != city) return;
      emit(state.copyWith(isLoadingMore: false, loadMoreFailed: true, errorMessage: _message(e)));
    }
  }

  Future<void> _onCityChanged(FeedCityChanged event, Emitter<FeedState> emit) async {
    if (event.city == state.city) return;
    final city = event.city;

    // A new state, not a copy: nothing of the previous city stays on screen.
    emit(FeedState.loading(city));
    try {
      final (items, hasMore) = await _getCityFeed(city.name);
      if (state.city != city) return;
      emit(state.copyWith(status: FeedStatus.success, items: items, hasMore: hasMore));
    } on Exception catch (e) {
      if (state.city != city) return;
      emit(state.copyWith(status: FeedStatus.failure, errorMessage: _message(e)));
    }
  }

  /// A failed refresh keeps the old list and says why.
  Future<void> _onRefreshed(FeedRefreshed event, Emitter<FeedState> emit) async {
    final city = state.city;
    if (city == null || state.status == FeedStatus.loading || state.isLoadingMore) return;

    emit(state.copyWith(status: FeedStatus.loading, loadMoreFailed: false, clearErrorMessage: true));
    try {
      final (items, hasMore) = await _getCityFeed(city.name);
      if (state.city != city) return;
      emit(state.copyWith(status: FeedStatus.success, items: items, hasMore: hasMore));
    } on Exception catch (e) {
      if (state.city != city) return;
      emit(state.copyWith(status: FeedStatus.failure, errorMessage: _message(e)));
      return;
    }
    // A refresh with a filter on brings the rest of the city back too.
    if (state.filter.needsFullList) await _loadAllPages(emit);
  }

  /// A failed page keeps the list, and `loadMoreFailed` makes the page offer a retry.
  Future<void> _onNextPageRequested(FeedNextPageRequested event, Emitter<FeedState> emit) async {
    final city = state.city;
    if (city == null || state.status != FeedStatus.success || !state.hasMore || state.isLoadingMore) return;

    final offset = state.items.length;
    emit(state.copyWith(isLoadingMore: true, loadMoreFailed: false, clearErrorMessage: true));
    try {
      final (items, hasMore) = await _getCityFeed(city.name, offset: offset);
      if (state.city != city || state.items.length != offset) return;
      emit(state.copyWith(items: [...state.items, ...items], hasMore: hasMore, isLoadingMore: false));
    } on Exception catch (e) {
      if (state.city != city || state.items.length != offset) return;
      emit(state.copyWith(isLoadingMore: false, loadMoreFailed: true, errorMessage: _message(e)));
    }
  }

  String _message(Exception e) => e.toString().replaceFirst('Exception: ', '');
}

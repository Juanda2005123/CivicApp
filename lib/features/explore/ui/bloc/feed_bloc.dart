import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../reports/domain/usecases/get_city_feed_usecase.dart';
import 'feed_event.dart';
import 'feed_state.dart';

/// Loads the community feed of the active city page by page (HU-19).
///
/// An answer that arrives after the citizen moved to another city (or after
/// the list changed under it) is dropped: each handler checks, once its
/// request returns, that the state still is the one it started from.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final GetCityFeedUseCase _getCityFeed;

  FeedBloc(this._getCityFeed) : super(const FeedState()) {
    on<FeedCityChanged>(_onCityChanged);
    on<FeedRefreshed>(_onRefreshed);
    on<FeedNextPageRequested>(_onNextPageRequested);
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
    }
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

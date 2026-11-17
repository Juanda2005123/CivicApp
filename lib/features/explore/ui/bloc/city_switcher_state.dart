import '../../../auth/domain/entities/city.dart';
import '../../domain/entities/city_options.dart';

enum CitySwitcherStatus { initial, loading, success, failure }

/// Single state: the options stay on screen while the citizen types.
class CitySwitcherState {
  final CitySwitcherStatus status;
  final CityOptions? options;
  final String query;
  final List<City> results;
  final String? errorMessage;

  const CitySwitcherState({
    this.status = CitySwitcherStatus.initial,
    this.options,
    this.query = '',
    this.results = const [],
    this.errorMessage,
  });

  /// True while the search box holds text: the page shows [results], not the shortcuts.
  bool get isSearching => query.trim().isNotEmpty;

  CitySwitcherState copyWith({
    CitySwitcherStatus? status,
    CityOptions? options,
    String? query,
    List<City>? results,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CitySwitcherState(
      status: status ?? this.status,
      options: options ?? this.options,
      query: query ?? this.query,
      results: results ?? this.results,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

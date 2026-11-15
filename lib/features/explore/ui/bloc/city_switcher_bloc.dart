import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_city_options_usecase.dart';
import '../../domain/usecases/search_cities_usecase.dart';
import 'city_switcher_event.dart';
import 'city_switcher_state.dart';

/// Feeds the city switcher sheet (HU-21): shortcuts and recents first, tolerant
/// search as the citizen types. Picking a city is the map's job (`CitySelected`).
class CitySwitcherBloc extends Bloc<CitySwitcherEvent, CitySwitcherState> {
  final GetCityOptionsUseCase _getOptions;
  final SearchCitiesUseCase _search;

  CitySwitcherBloc(this._getOptions, this._search) : super(const CitySwitcherState()) {
    on<CitySwitcherOpened>(_onOpened);
    on<CityQueryChanged>(_onQueryChanged);
  }

  Future<void> _onOpened(CitySwitcherOpened event, Emitter<CitySwitcherState> emit) async {
    emit(state.copyWith(status: CitySwitcherStatus.loading, clearErrorMessage: true));
    try {
      final options = await _getOptions();
      emit(
        state.copyWith(
          status: CitySwitcherStatus.success,
          options: options,
          results: _search(options.all, state.query),
        ),
      );
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: CitySwitcherStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void _onQueryChanged(CityQueryChanged event, Emitter<CitySwitcherState> emit) {
    final options = state.options;
    emit(
      state.copyWith(
        query: event.query,
        results: options == null ? const [] : _search(options.all, event.query),
      ),
    );
  }
}

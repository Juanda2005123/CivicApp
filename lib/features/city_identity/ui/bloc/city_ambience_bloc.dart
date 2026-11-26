import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/city_ref.dart';
import '../../domain/entities/day_part.dart';
import '../../domain/usecases/get_city_identity_usecase.dart';
import '../../domain/usecases/get_featured_cities_usecase.dart';
import '../../domain/usecases/get_last_city_usecase.dart';
import '../../domain/usecases/save_last_city_usecase.dart';
import 'city_ambience_event.dart';
import 'city_ambience_state.dart';

/// App-wide look (docs/design/04-city-identity.md, section 3): which city the
/// app is dressed for and which moment of the day it is. Provided above
/// `MaterialApp` because the theme is built from its state (AGENTS.md §5).
///
/// The moment of the day comes from the clock, when the app opens and when it
/// comes back to the foreground. The citizen cannot choose it.
class CityAmbienceBloc extends Bloc<CityAmbienceEvent, CityAmbienceState> {
  final GetCityIdentityUseCase _getIdentity;
  final GetLastCityUseCase _getLastCity;
  final SaveLastCityUseCase _saveLastCity;
  final DateTime Function() _now;

  /// A city arrived while the remembered one was still being read.
  bool _cityKnown = false;

  CityAmbienceBloc(
    this._getIdentity,
    GetFeaturedCitiesUseCase getFeaturedCities,
    this._getLastCity,
    this._saveLastCity, {
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(CityAmbienceState(
          identity: _getIdentity(''),
          featured: getFeaturedCities(),
          dayPart: DayPart.of((now ?? DateTime.now)()),
        )) {
    on<CityAmbienceStarted>(_onStarted);
    on<ActiveCityChanged>(_onActiveCityChanged);
    on<ReferenceCityChanged>(_onReferenceCityChanged);
    on<AppResumed>(_onAppResumed);
  }

  Future<void> _onStarted(CityAmbienceStarted event, Emitter<CityAmbienceState> emit) async {
    emit(state.copyWith(dayPart: DayPart.of(_now())));
    final last = await _getLastCity();
    if (last == null || _cityKnown) return;
    emit(state.copyWith(identity: _getIdentity(last.name, department: last.department)));
  }

  Future<void> _onActiveCityChanged(ActiveCityChanged event, Emitter<CityAmbienceState> emit) async {
    _cityKnown = true;
    final identity = _getIdentity(event.name, department: event.department);
    if (identity == state.identity) return;

    emit(state.copyWith(
      identity: identity,
      citySwitches: event.switched ? state.citySwitches + 1 : state.citySwitches,
      arrivedBySwitch: event.switched,
    ));
    await _saveLastCity(CityRef(name: event.name, department: event.department));
  }

  void _onReferenceCityChanged(ReferenceCityChanged event, Emitter<CityAmbienceState> emit) {
    emit(state.copyWith(reference: _getIdentity(event.name), arrivedBySwitch: false));
  }

  void _onAppResumed(AppResumed event, Emitter<CityAmbienceState> emit) {
    emit(state.copyWith(dayPart: DayPart.of(_now()), arrivedBySwitch: false));
  }
}

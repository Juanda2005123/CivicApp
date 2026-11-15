import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/repositories/location_repository.dart';
import '../../../auth/domain/usecases/open_location_settings_usecase.dart';
import '../../domain/usecases/switch_city_usecase.dart';
import '../../../reports/domain/usecases/get_city_map_usecase.dart';
import '../../../reports/domain/usecases/get_current_location_usecase.dart';
import 'map_event.dart';
import 'map_state.dart';

/// Loads the city the map opens on and the markers of its reports, and finds
/// the citizen's position for "Centrar en mi ubicación" (HU-13).
class MapBloc extends Bloc<MapEvent, MapState> {
  final GetCityMapUseCase _getCityMap;
  final GetCurrentLocationUseCase _getCurrentLocation;
  final OpenLocationSettingsUseCase _openLocationSettings;
  final SwitchCityUseCase _switchCity;

  MapBloc(this._getCityMap, this._getCurrentLocation, this._openLocationSettings, this._switchCity)
      : super(const MapState()) {
    on<MapStarted>(_onStarted);
    on<CitySelected>(_onCitySelected);
    on<MyLocationRequested>(_onMyLocationRequested);
    on<LocationSettingsRequested>(_onLocationSettingsRequested);
  }

  Future<void> _onStarted(MapStarted event, Emitter<MapState> emit) async {
    if (state.status == MapStatus.loading) return;
    emit(state.copyWith(status: MapStatus.loading, clearErrorMessage: true));
    try {
      // A reload keeps the city already on screen (the one the citizen picked).
      final (city, markers) = await _getCityMap(city: state.city);
      emit(state.copyWith(status: MapStatus.success, city: city, markers: markers));
    } on Exception catch (e) {
      emit(state.copyWith(status: MapStatus.failure, errorMessage: _message(e)));
      return;
    }

    // First load only (HU-03): center on the citizen. If the permission is not
    // granted yet this opens the system dialog; the OS stops showing it once
    // the permission is blocked (Android after two denials, iOS after one).
    // Any failure stays silent and keeps the city view: the "Centrar en mi
    // ubicación" button and its modal handle a later attempt.
    if (state.myLocation != null) return;
    try {
      final position = await _getCurrentLocation();
      emit(state.copyWith(myLocationStatus: MyLocationStatus.found, myLocation: position));
    } on Exception {
      return;
    }
  }

  /// Saves the city first: if that fails the map keeps the previous city and
  /// its markers, and the page shows the message.
  Future<void> _onCitySelected(CitySelected event, Emitter<MapState> emit) async {
    if (state.status == MapStatus.loading) return;
    emit(state.copyWith(status: MapStatus.loading, clearErrorMessage: true));
    try {
      await _switchCity(event.city);
      final (city, markers) = await _getCityMap(city: event.city);
      emit(state.copyWith(status: MapStatus.success, city: city, markers: markers));
    } on Exception catch (e) {
      emit(state.copyWith(status: MapStatus.failure, errorMessage: _message(e)));
    }
  }

  Future<void> _onMyLocationRequested(MyLocationRequested event, Emitter<MapState> emit) async {
    if (state.myLocationStatus == MyLocationStatus.locating) return;
    emit(state.copyWith(myLocationStatus: MyLocationStatus.locating, clearMyLocationMessage: true));
    try {
      final position = await _getCurrentLocation();
      emit(state.copyWith(myLocationStatus: MyLocationStatus.found, myLocation: position));
    } on Exception catch (e) {
      final message = _message(e);
      emit(state.copyWith(
        myLocationStatus: message == LocationRepository.blockedMessage
            ? MyLocationStatus.blocked
            : MyLocationStatus.failure,
        myLocationMessage: message,
      ));
    }
  }

  /// No emit on success: the notice stays until the user tries again.
  Future<void> _onLocationSettingsRequested(
    LocationSettingsRequested event,
    Emitter<MapState> emit,
  ) async {
    try {
      await _openLocationSettings();
    } on Exception catch (e) {
      emit(state.copyWith(myLocationStatus: MyLocationStatus.failure, myLocationMessage: _message(e)));
    }
  }

  String _message(Exception e) => e.toString().replaceFirst('Exception: ', '');
}

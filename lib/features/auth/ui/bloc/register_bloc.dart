import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/detect_nearest_city_usecase.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/get_cities_usecase.dart';
import '../../domain/usecases/open_location_settings_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final GetCitiesUseCase _getCities;
  final DetectNearestCityUseCase _detectNearestCity;
  final OpenLocationSettingsUseCase _openLocationSettings;
  final SignUpUseCase _signUp;

  RegisterBloc(
    this._getCities,
    this._detectNearestCity,
    this._openLocationSettings,
    this._signUp,
  ) : super(const RegisterState()) {
    on<RegisterStarted>(_onStarted);
    on<CitySelected>(_onCitySelected);
    on<NearestCityRequested>(_onNearestCityRequested);
    on<LocationSettingsRequested>(_onLocationSettingsRequested);
    on<RegisterSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(RegisterStarted event, Emitter<RegisterState> emit) async {
    try {
      emit(state.copyWith(cities: await _getCities()));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: _message(e),
      ));
    }
  }

  void _onCitySelected(CitySelected event, Emitter<RegisterState> emit) {
    emit(state.copyWith(
      selectedCityId: event.cityId,
      gpsStatus: GpsStatus.idle,
      clearGpsMessage: true,
    ));
  }

  Future<void> _onNearestCityRequested(
    NearestCityRequested event,
    Emitter<RegisterState> emit,
  ) async {
    emit(state.copyWith(gpsStatus: GpsStatus.detecting, clearGpsMessage: true));
    try {
      final city = await _detectNearestCity();
      emit(state.copyWith(
        selectedCityId: city.id,
        gpsStatus: GpsStatus.success,
        gpsMessage: 'Ciudad detectada: ${city.displayName}',
      ));
    } on Exception catch (e) {
      final message = _message(e);
      emit(state.copyWith(
        gpsStatus: message == LocationRepository.blockedMessage
            ? GpsStatus.blocked
            : GpsStatus.failure,
        gpsMessage: message,
      ));
    }
  }

  /// No emit on success: the notice stays until the user tries the GPS again.
  Future<void> _onLocationSettingsRequested(
    LocationSettingsRequested event,
    Emitter<RegisterState> emit,
  ) async {
    try {
      await _openLocationSettings();
    } on Exception catch (e) {
      emit(state.copyWith(gpsStatus: GpsStatus.failure, gpsMessage: _message(e)));
    }
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    final city = state.selectedCity;
    if (city == null) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: 'Elige tu ciudad.',
      ));
      return;
    }

    emit(state.copyWith(status: RegisterStatus.loading, clearErrorMessage: true));
    try {
      final profile = await _signUp(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
        cityName: city.name,
      );
      emit(state.copyWith(status: RegisterStatus.success, profile: profile));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        errorMessage: _message(e),
      ));
    }
  }

  String _message(Exception e) => e.toString().replaceFirst('Exception: ', '');
}

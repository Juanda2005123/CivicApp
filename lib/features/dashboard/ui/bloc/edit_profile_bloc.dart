import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/profile.dart';
import '../../../auth/domain/repositories/location_repository.dart';
import '../../../auth/domain/usecases/change_password_usecase.dart';
import '../../../auth/domain/usecases/detect_nearest_city_usecase.dart';
import '../../../auth/domain/usecases/get_cities_usecase.dart';
import '../../../auth/domain/usecases/open_location_settings_usecase.dart';
import '../../../auth/domain/usecases/update_personal_info_usecase.dart';
import 'edit_profile_event.dart';
import 'edit_profile_state.dart';

/// Handles personal information, email, and password updates (HU-04).
class EditProfileBloc extends Bloc<EditProfileEvent, EditProfileState> {
  final GetCitiesUseCase _getCities;
  final DetectNearestCityUseCase _detectNearestCity;
  final OpenLocationSettingsUseCase _openLocationSettings;
  final UpdatePersonalInfoUseCase _updatePersonalInfo;
  final ChangePasswordUseCase _changePassword;

  EditProfileBloc(
    this._getCities,
    this._detectNearestCity,
    this._openLocationSettings,
    this._updatePersonalInfo,
    this._changePassword,
  ) : super(const EditProfileState()) {
    on<EditProfileStarted>(_onStarted);
    on<EditProfileCityDetectRequested>(_onCityDetectRequested);
    on<EditProfileLocationSettingsRequested>(_onLocationSettingsRequested);
    on<EditProfileSaved>(_onSaved);
    on<EditProfilePasswordChanged>(_onPasswordChanged);
  }

  Future<void> _onStarted(EditProfileStarted event, Emitter<EditProfileState> emit) async {
    emit(state.copyWith(
      status: EditProfileStatus.loadingCities,
      profile: event.profile,
      clearErrorMessage: true,
    ));
    try {
      final cities = await _getCities();
      emit(state.copyWith(status: EditProfileStatus.initial, cities: cities));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: EditProfileStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onCityDetectRequested(
    EditProfileCityDetectRequested event,
    Emitter<EditProfileState> emit,
  ) async {
    if (state.locationStatus == EditProfileLocationStatus.detecting) return;
    emit(state.copyWith(
      locationStatus: EditProfileLocationStatus.detecting,
      clearLocationErrorMessage: true,
    ));
    try {
      final city = await _detectNearestCity();
      emit(state.copyWith(
        locationStatus: EditProfileLocationStatus.detected,
        detectedCity: city,
      ));
    } on Exception catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message == LocationRepository.blockedMessage) {
        emit(state.copyWith(
          locationStatus: EditProfileLocationStatus.blocked,
          locationErrorMessage: message,
        ));
      } else {
        emit(state.copyWith(
          locationStatus: EditProfileLocationStatus.error,
          locationErrorMessage: message,
        ));
      }
    }
  }

  Future<void> _onLocationSettingsRequested(
    EditProfileLocationSettingsRequested event,
    Emitter<EditProfileState> emit,
  ) async {
    await _openLocationSettings();
  }

  Future<void> _onSaved(EditProfileSaved event, Emitter<EditProfileState> emit) async {
    final profile = state.profile;
    if (state.status == EditProfileStatus.saving || profile == null) return;
    emit(state.copyWith(
      status: EditProfileStatus.saving,
      emailVerificationPending: false,
      clearErrorMessage: true,
    ));
    try {
      final result = await _updatePersonalInfo(
        userId: profile.id,
        currentEmail: profile.email,
        fullName: event.fullName,
        cityName: event.cityName,
        email: event.email,
      );
      final updatedProfile = Profile(
        id: profile.id,
        email: profile.email,
        fullName: event.fullName.trim(),
        cityName: event.cityName.trim(),
        lastCityName: profile.lastCityName,
        rankId: profile.rankId,
        rankName: profile.rankName,
        experiencePoints: profile.experiencePoints,
        isActive: profile.isActive,
      );
      emit(state.copyWith(
        status: EditProfileStatus.saved,
        profile: updatedProfile,
        emailVerificationPending: result.emailVerificationPending,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: EditProfileStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<void> _onPasswordChanged(
    EditProfilePasswordChanged event,
    Emitter<EditProfileState> emit,
  ) async {
    final profile = state.profile;
    if (state.passwordStatus == PasswordChangeStatus.saving || profile == null) return;
    emit(state.copyWith(
      passwordStatus: PasswordChangeStatus.saving,
      clearPasswordErrorMessage: true,
    ));
    try {
      await _changePassword(
        currentEmail: profile.email,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(state.copyWith(passwordStatus: PasswordChangeStatus.saved));
    } on Exception catch (e) {
      emit(state.copyWith(
        passwordStatus: PasswordChangeStatus.failure,
        passwordErrorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}

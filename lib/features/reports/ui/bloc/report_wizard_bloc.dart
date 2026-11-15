import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/detect_nearest_city_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/open_location_settings_usecase.dart';

import '../../domain/entities/picked_photo.dart';
import '../../domain/usecases/create_incident_usecase.dart';
import '../../domain/usecases/endorse_incident_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_current_location_usecase.dart';
import '../../domain/usecases/get_nearby_incidents_usecase.dart';
import '../../domain/usecases/pick_photo_usecase.dart';
import '../../domain/entities/suggested_address.dart';
import '../../domain/usecases/suggest_address_usecase.dart';
import '../../domain/validators/report_validators.dart';
import 'report_wizard_event.dart';
import 'report_wizard_state.dart';

class ReportWizardBloc extends Bloc<ReportWizardEvent, ReportWizardState> {
  final GetCategoriesUseCase _getCategories;
  final GetNearbyIncidentsUseCase _getNearbyIncidents;
  final CreateIncidentUseCase _createIncident;
  final EndorseIncidentUseCase _endorseIncident;
  final GetCurrentProfileUseCase _getCurrentProfile;
  final GetCurrentLocationUseCase _getCurrentLocation;
  final PickPhotoUseCase _pickPhoto;
  final DetectNearestCityUseCase _detectNearestCity;
  final OpenLocationSettingsUseCase _openLocationSettings;
  final SuggestAddressUseCase _suggestAddress;

  ReportWizardBloc(
    this._getCategories,
    this._getNearbyIncidents,
    this._createIncident,
    this._endorseIncident,
    this._getCurrentProfile,
    this._getCurrentLocation,
    this._pickPhoto,
    this._detectNearestCity,
    this._openLocationSettings,
    this._suggestAddress,
  ) : super(const ReportWizardState()) {
    on<WizardStarted>(_onWizardStarted);
    on<CurrentLocationRequested>(_onCurrentLocationRequested);
    on<LocationSettingsRequested>(_onLocationSettingsRequested);
    on<LocationPitched>(_onLocationPitched);
    on<CategoryAndSeveritySelected>(_onCategoryAndSeveritySelected);
    on<NearbyReportEndorsed>(_onNearbyReportEndorsed);
    on<NearbyCheckDismissed>(_onNearbyCheckDismissed);
    on<PhotosUpdated>(_onPhotosUpdated);
    on<PhotoPickRequested>(_onPhotoPickRequested);
    on<PhotoRemoved>(_onPhotoRemoved);
    on<DetailsSubmitted>(_onDetailsSubmitted);
    on<StepNavigated>(_onStepNavigated);
    on<ReportSubmitConfirmed>(_onReportSubmitConfirmed);
  }

  Future<void> _onWizardStarted(
    WizardStarted event,
    Emitter<ReportWizardState> emit,
  ) async {
    emit(state.copyWith(status: WizardStatus.loading, clearErrorMessage: true));
    try {
      final categories = await _getCategories();
      final profile = await _getCurrentProfile();

      Coordinates? initialCoords = state.coordinates;
      String? initialCity = state.city ?? profile?.cityName;

      // Proactively detect real device GPS or fall back to user's registered city
      Coordinates? deviceCoords;
      try {
        deviceCoords = await _getCurrentLocation();
        initialCoords = deviceCoords;
        try {
          final detectedCity = await _detectNearestCity();
          initialCity = detectedCity.name;
        } catch (_) {}
      } catch (_) {
        if (initialCoords == null && initialCity != null) {
          initialCoords = _resolveFallbackCoordinatesForCity(initialCity);
        }
      }

      initialCoords ??= const Coordinates(latitude: 3.4516, longitude: -76.5320);
      initialCity ??= 'Cali';

      emit(state.copyWith(
        status: WizardStatus.ready,
        categories: categories,
        coordinates: initialCoords,
        city: initialCity,
        clearErrorMessage: true,
      ));

      // With a real position, the address is suggested without waiting for
      // a "Mi GPS" tap (HU-26).
      if (deviceCoords != null) await _suggestAddressAt(deviceCoords, emit);
    } on Exception catch (e) {
      emit(state.copyWith(
        status: WizardStatus.failure,
        errorMessage: _cleanExceptionMessage(e),
      ));
    }
  }

  Future<void> _onCurrentLocationRequested(
    CurrentLocationRequested event,
    Emitter<ReportWizardState> emit,
  ) async {
    emit(state.copyWith(
      isLocating: true,
      isLocationBlocked: false,
      clearLocationStatusMessage: true,
      clearErrorMessage: true,
      clearSuggestedAddress: true,
      clearAddressSuggestionMessage: true,
    ));
    try {
      final coords = await _getCurrentLocation();
      String? cityName = state.city;
      try {
        final nearest = await _detectNearestCity();
        cityName = nearest.name;
      } catch (_) {}

      emit(state.copyWith(
        isLocating: false,
        coordinates: coords,
        city: cityName,
        locationStatusMessage:
            'GPS detectado: (${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}) en $cityName',
        clearErrorMessage: true,
      ));
      await _suggestAddressAt(coords, emit);
    } on Exception catch (e) {
      final message = _cleanExceptionMessage(e);
      final blocked = message == LocationRepository.blockedMessage;
      emit(state.copyWith(
        isLocating: false,
        isLocationBlocked: blocked,
        locationStatusMessage: blocked ? message : 'No se pudo obtener el GPS: $message',
      ));
    }
  }

  /// HU-26: suggests the address of [coords]; the cross street arrives a few
  /// seconds after the rest. A failure (slow, offline, rate-limited) or a
  /// missing piece never blocks the form: a message asks to type it by hand.
  Future<void> _suggestAddressAt(Coordinates coords, Emitter<ReportWizardState> emit) async {
    emit(state.copyWith(
      isSuggestingAddress: true,
      clearSuggestedAddress: true,
      clearAddressSuggestionMessage: true,
    ));
    String? message;
    try {
      SuggestedAddress? suggestion;
      await for (suggestion in _suggestAddress(coords)) {
        emit(state.copyWith(suggestedAddress: suggestion));
      }
      if (suggestion?.mainRoad == null) {
        message = 'No reconocimos la vía en este punto. Escribe la dirección a mano.';
      } else if (suggestion?.crossRoad == null) {
        message = 'No encontramos el cruce. Escríbelo a mano.';
      }
    } on Exception catch (e) {
      message = '${_cleanExceptionMessage(e)} Escríbela a mano.';
    }
    emit(state.copyWith(isSuggestingAddress: false, addressSuggestionMessage: message));
  }

  /// No emit on success: the notice stays until the user tries the GPS again.
  Future<void> _onLocationSettingsRequested(
    LocationSettingsRequested event,
    Emitter<ReportWizardState> emit,
  ) async {
    try {
      await _openLocationSettings();
    } on Exception catch (e) {
      emit(state.copyWith(
        isLocationBlocked: false,
        locationStatusMessage: _cleanExceptionMessage(e),
      ));
    }
  }

  void _onLocationPitched(
    LocationPitched event,
    Emitter<ReportWizardState> emit,
  ) {
    try {
      ReportValidators.validateCoordinates(event.coordinates);
      ReportValidators.validateAddress(event.formattedAddress);
      ReportValidators.validateNeighborhood(event.neighborhood);

      emit(state.copyWith(
        coordinates: event.coordinates,
        formattedAddress: event.formattedAddress,
        neighborhood: event.neighborhood,
        city: event.city,
        currentStep: 2,
        clearErrorMessage: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        errorMessage: _cleanExceptionMessage(e),
      ));
    }
  }

  Future<void> _onCategoryAndSeveritySelected(
    CategoryAndSeveritySelected event,
    Emitter<ReportWizardState> emit,
  ) async {
    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      severity: event.severity,
      isCheckingNearby: true,
      clearErrorMessage: true,
    ));

    // If coordinates are available, inspect for nearby duplicates (HU-08)
    if (state.coordinates != null) {
      try {
        final nearby = await _getNearbyIncidents(
          coordinates: state.coordinates!,
          categoryId: event.categoryId,
        );

        emit(state.copyWith(
          nearbyIncidents: nearby,
          isCheckingNearby: false,
          currentStep: nearby.isNotEmpty ? 2 : 3,
          clearErrorMessage: true,
        ));
        return;
      } catch (_) {
        // Nearby inspection failure should not block the citizen from proceeding
      }
    }

    emit(state.copyWith(
      isCheckingNearby: false,
      currentStep: 3,
      clearErrorMessage: true,
    ));
  }

  Future<void> _onNearbyReportEndorsed(
    NearbyReportEndorsed event,
    Emitter<ReportWizardState> emit,
  ) async {
    final profile = await _getCurrentProfile();
    if (profile == null) {
      emit(state.copyWith(
        status: WizardStatus.failure,
        errorMessage: 'Debes iniciar sesión para apoyar un reporte.',
      ));
      return;
    }

    emit(state.copyWith(status: WizardStatus.submitting, clearErrorMessage: true));
    try {
      await _endorseIncident(
        incidentId: event.incidentId,
        userId: profile.id,
      );
      emit(state.copyWith(
        status: WizardStatus.success,
        isEndorsedNearby: true,
        clearErrorMessage: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: WizardStatus.failure,
        errorMessage: _cleanExceptionMessage(e),
      ));
    }
  }

  void _onNearbyCheckDismissed(
    NearbyCheckDismissed event,
    Emitter<ReportWizardState> emit,
  ) {
    emit(state.copyWith(currentStep: 3, clearErrorMessage: true));
  }

  void _onPhotosUpdated(
    PhotosUpdated event,
    Emitter<ReportWizardState> emit,
  ) {
    try {
      ReportValidators.validatePhotos(event.photos);
      emit(state.copyWith(
        photos: event.photos,
        clearErrorMessage: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        errorMessage: _cleanExceptionMessage(e),
      ));
    }
  }

  Future<void> _onPhotoPickRequested(
    PhotoPickRequested event,
    Emitter<ReportWizardState> emit,
  ) async {
    if (state.photos.length >= ReportValidators.maxPhotosAllowed) {
      emit(state.copyWith(
        errorMessage: 'Ya has alcanzado el límite de ${ReportValidators.maxPhotosAllowed} fotos.',
      ));
      return;
    }

    try {
      final photo = await _pickPhoto(fromCamera: event.fromCamera);
      if (photo == null) return;

      final updated = List<PickedPhoto>.from(state.photos)..add(photo);
      ReportValidators.validatePhotos(updated);

      emit(state.copyWith(
        photos: updated,
        clearErrorMessage: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        errorMessage: _cleanExceptionMessage(e),
      ));
    }
  }

  void _onPhotoRemoved(
    PhotoRemoved event,
    Emitter<ReportWizardState> emit,
  ) {
    if (event.index < 0 || event.index >= state.photos.length) return;
    final updated = List<PickedPhoto>.from(state.photos)..removeAt(event.index);
    emit(state.copyWith(
      photos: updated,
      clearErrorMessage: true,
    ));
  }

  void _onDetailsSubmitted(
    DetailsSubmitted event,
    Emitter<ReportWizardState> emit,
  ) {
    try {
      ReportValidators.validateTitle(event.title);
      ReportValidators.validateDescription(event.description);

      emit(state.copyWith(
        title: event.title.trim(),
        description: event.description.trim(),
        dimensions: event.dimensions?.trim(),
        currentStep: 5,
        clearErrorMessage: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        errorMessage: _cleanExceptionMessage(e),
      ));
    }
  }

  void _onStepNavigated(
    StepNavigated event,
    Emitter<ReportWizardState> emit,
  ) {
    if (event.targetStep >= 1 && event.targetStep <= 5) {
      emit(state.copyWith(
        currentStep: event.targetStep,
        clearErrorMessage: true,
      ));
    }
  }

  Future<void> _onReportSubmitConfirmed(
    ReportSubmitConfirmed event,
    Emitter<ReportWizardState> emit,
  ) async {
    if (state.status == WizardStatus.submitting) return;

    emit(state.copyWith(status: WizardStatus.submitting, clearErrorMessage: true));

    final profile = await _getCurrentProfile();
    if (profile == null) {
      emit(state.copyWith(
        status: WizardStatus.failure,
        errorMessage: 'Debes iniciar sesión para publicar un reporte.',
      ));
      return;
    }

    if (state.coordinates == null ||
        state.selectedCategoryId == null ||
        state.formattedAddress == null ||
        state.neighborhood == null) {
      emit(state.copyWith(
        status: WizardStatus.failure,
        errorMessage: 'Faltan datos obligatorios para publicar el reporte.',
      ));
      return;
    }

    try {
      final published = await _createIncident(
        reporterId: profile.id,
        categoryId: state.selectedCategoryId!,
        title: state.title,
        description: state.description,
        severity: state.severity,
        estimatedDimensions: state.dimensions,
        coordinates: state.coordinates!,
        formattedAddress: state.formattedAddress!,
        neighborhood: state.neighborhood!,
        city: state.city ?? 'Cali',
        photos: state.photos,
      );

      emit(state.copyWith(
        status: WizardStatus.success,
        publishedIncident: published,
        clearErrorMessage: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: WizardStatus.failure,
        errorMessage: _cleanExceptionMessage(e),
      ));
    }
  }

  Coordinates _resolveFallbackCoordinatesForCity(String cityName) {
    final lower = cityName.toLowerCase().trim();
    if (lower.contains('popay')) {
      return const Coordinates(latitude: 2.4448, longitude: -76.6147);
    }
    if (lower.contains('bogot')) {
      return const Coordinates(latitude: 4.7110, longitude: -74.0721);
    }
    if (lower.contains('medell')) {
      return const Coordinates(latitude: 6.2442, longitude: -75.5812);
    }
    if (lower.contains('barranquill')) {
      return const Coordinates(latitude: 10.9685, longitude: -74.7813);
    }
    if (lower.contains('bucaramang')) {
      return const Coordinates(latitude: 7.1254, longitude: -73.1198);
    }
    if (lower.contains('pasto')) {
      return const Coordinates(latitude: 1.2136, longitude: -77.2811);
    }
    return const Coordinates(latitude: 3.4516, longitude: -76.5320); // Cali default
  }

  String _cleanExceptionMessage(Exception e) {
    return e.toString().replaceFirst('Exception: ', '').trim();
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';

import '../../domain/usecases/create_incident_usecase.dart';
import '../../domain/usecases/endorse_incident_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_nearby_incidents_usecase.dart';
import '../../domain/validators/report_validators.dart';
import 'report_wizard_event.dart';
import 'report_wizard_state.dart';

class ReportWizardBloc extends Bloc<ReportWizardEvent, ReportWizardState> {
  final GetCategoriesUseCase _getCategories;
  final GetNearbyIncidentsUseCase _getNearbyIncidents;
  final CreateIncidentUseCase _createIncident;
  final EndorseIncidentUseCase _endorseIncident;
  final GetCurrentProfileUseCase _getCurrentProfile;

  ReportWizardBloc(
    this._getCategories,
    this._getNearbyIncidents,
    this._createIncident,
    this._endorseIncident,
    this._getCurrentProfile,
  ) : super(const ReportWizardState()) {
    on<WizardStarted>(_onWizardStarted);
    on<LocationPitched>(_onLocationPitched);
    on<CategoryAndSeveritySelected>(_onCategoryAndSeveritySelected);
    on<NearbyReportEndorsed>(_onNearbyReportEndorsed);
    on<NearbyCheckDismissed>(_onNearbyCheckDismissed);
    on<PhotosUpdated>(_onPhotosUpdated);
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
      emit(state.copyWith(
        status: WizardStatus.ready,
        categories: categories,
        clearErrorMessage: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: WizardStatus.failure,
        errorMessage: _cleanExceptionMessage(e),
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

    // If coordinates are available, inspect for nearby duplicates
    if (state.coordinates != null) {
      try {
        final nearby = await _getNearbyIncidents(
          coordinates: state.coordinates!,
          categoryId: event.categoryId,
        );

        emit(state.copyWith(
          nearbyIncidents: nearby,
          isCheckingNearby: false,
          // If duplicates are detected, stay on Step 2 so citizen can inspect (HU-08/HU-09)
          // Otherwise, proceed directly to Step 3 (photos)
          currentStep: nearby.isNotEmpty ? 2 : 3,
          clearErrorMessage: true,
        ));
        return;
      } catch (_) {
        // Nearby inspection failure should not block the user from proceeding
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

  String _cleanExceptionMessage(Exception e) {
    return e.toString().replaceFirst('Exception: ', '').trim();
  }
}

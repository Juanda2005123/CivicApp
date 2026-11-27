import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/usecases/get_current_profile_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/pick_photo_usecase.dart';
import '../../domain/usecases/update_incident_usecase.dart';
import '../../domain/validators/report_validators.dart';
import 'edit_report_event.dart';
import 'edit_report_state.dart';

/// Drives the edit form of the author's report (HU-18): the category, the
/// severity, the photos and the text. Whether the window is still open is the
/// server's call; if it closed with the screen open, its message comes back as
/// the [EditReportState.errorMessage] and the form keeps what was typed.
class EditReportBloc extends Bloc<EditReportEvent, EditReportState> {
  final GetCategoriesUseCase _getCategories;
  final PickPhotoUseCase _pickPhoto;
  final UpdateIncidentUseCase _updateIncident;
  final GetCurrentProfileUseCase _getCurrentProfile;

  EditReportBloc(
    this._getCategories,
    this._pickPhoto,
    this._updateIncident,
    this._getCurrentProfile,
  ) : super(const EditReportState()) {
    on<EditReportStarted>(_onStarted);
    on<EditCategorySelected>(_onCategorySelected);
    on<EditSeveritySelected>(_onSeveritySelected);
    on<EditKeptPhotoRemoved>(_onKeptPhotoRemoved);
    on<EditPhotoPickRequested>(_onPhotoPickRequested);
    on<EditAddedPhotoRemoved>(_onAddedPhotoRemoved);
    on<EditSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(EditReportStarted event, Emitter<EditReportState> emit) async {
    final incident = event.incident;
    emit(EditReportState(
      status: EditReportStatus.loading,
      incident: incident,
      categoryId: incident.categoryId,
      severity: incident.severity,
      keptPhotos: incident.photos,
    ));
    try {
      final categories = await _getCategories();
      emit(state.copyWith(status: EditReportStatus.ready, categories: categories));
    } on Exception catch (e) {
      emit(state.copyWith(status: EditReportStatus.failure, errorMessage: _message(e)));
    }
  }

  void _onCategorySelected(EditCategorySelected event, Emitter<EditReportState> emit) {
    emit(state.copyWith(categoryId: event.categoryId, clearErrorMessage: true));
  }

  void _onSeveritySelected(EditSeveritySelected event, Emitter<EditReportState> emit) {
    emit(state.copyWith(severity: event.severity, clearErrorMessage: true));
  }

  void _onKeptPhotoRemoved(EditKeptPhotoRemoved event, Emitter<EditReportState> emit) {
    emit(state.copyWith(
      keptPhotos: state.keptPhotos.where((photo) => photo.id != event.photoId).toList(),
      clearErrorMessage: true,
    ));
  }

  Future<void> _onPhotoPickRequested(EditPhotoPickRequested event, Emitter<EditReportState> emit) async {
    if (!state.canAddPhoto) {
      emit(state.copyWith(errorMessage: 'Ya has alcanzado el límite de ${ReportValidators.maxPhotosAllowed} fotos.'));
      return;
    }
    try {
      final photo = await _pickPhoto(fromCamera: event.fromCamera);
      if (photo == null) return;

      // A bad photo is refused now with the reason, and the ones already chosen stay.
      ReportValidators.validatePhotos([photo]);
      emit(state.copyWith(addedPhotos: [...state.addedPhotos, photo], clearErrorMessage: true));
    } on Exception catch (e) {
      emit(state.copyWith(errorMessage: _message(e)));
    }
  }

  void _onAddedPhotoRemoved(EditAddedPhotoRemoved event, Emitter<EditReportState> emit) {
    if (event.index < 0 || event.index >= state.addedPhotos.length) return;
    emit(state.copyWith(
      addedPhotos: [...state.addedPhotos]..removeAt(event.index),
      clearErrorMessage: true,
    ));
  }

  Future<void> _onSubmitted(EditSubmitted event, Emitter<EditReportState> emit) async {
    final incident = state.incident;
    final categoryId = state.categoryId;
    if (incident == null || categoryId == null || state.status == EditReportStatus.saving) return;

    emit(state.copyWith(status: EditReportStatus.saving, clearErrorMessage: true));
    try {
      final profile = await _getCurrentProfile();
      if (profile == null) throw Exception('Debes iniciar sesión para editar tu reporte.');

      final saved = await _updateIncident(
        incident: incident,
        userId: profile.id,
        categoryId: categoryId,
        title: event.title,
        description: event.description,
        severity: state.severity,
        estimatedDimensions: event.dimensions,
        keptPhotos: state.keptPhotos,
        addedPhotos: state.addedPhotos,
      );
      emit(state.copyWith(status: EditReportStatus.saved, savedIncident: saved));
    } on Exception catch (e) {
      // Everything typed and picked stays for another try.
      emit(state.copyWith(status: EditReportStatus.ready, errorMessage: _message(e)));
    }
  }

  String _message(Exception e) => e.toString().replaceFirst('Exception: ', '').trim();
}

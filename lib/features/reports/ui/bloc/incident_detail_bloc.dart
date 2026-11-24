import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/usecases/get_current_profile_usecase.dart';
import '../../domain/usecases/delete_incident_usecase.dart';
import '../../domain/usecases/get_incident_by_id_usecase.dart';
import '../../domain/usecases/toggle_endorsement_usecase.dart';
import 'incident_detail_event.dart';
import 'incident_detail_state.dart';

class IncidentDetailBloc extends Bloc<IncidentDetailEvent, IncidentDetailState> {
  final GetIncidentByIdUseCase _getIncidentById;
  final GetCurrentProfileUseCase _getCurrentProfile;
  final ToggleEndorsementUseCase _toggleEndorsement;
  final DeleteIncidentUseCase _deleteIncident;

  IncidentDetailBloc(
    this._getIncidentById,
    this._getCurrentProfile,
    this._toggleEndorsement,
    this._deleteIncident,
  ) : super(const IncidentDetailState()) {
    on<IncidentDetailStarted>(_onIncidentDetailStarted);
    on<IncidentEndorsementToggled>(_onEndorsementToggled);
    on<IncidentDeleteRequested>(_onDeleteRequested);
    on<IncidentReloaded>(_onReloaded);
  }

  Future<void> _onIncidentDetailStarted(
    IncidentDetailStarted event,
    Emitter<IncidentDetailState> emit,
  ) async {
    emit(state.copyWith(status: IncidentDetailStatus.loading, clearErrorMessage: true));
    try {
      final viewerId = await _viewerId();
      final incident = await _getIncidentById(event.idOrTrackingCode);
      emit(state.copyWith(
        status: IncidentDetailStatus.success,
        incident: incident,
        viewerId: viewerId,
        clearErrorMessage: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: IncidentDetailStatus.failure,
        errorMessage: _message(e),
      ));
    }
  }

  /// Draws the tap at once and asks the server. If the request fails the report
  /// goes back to how it was and the reason reaches the screen (HU-15, criterion 5).
  /// On success the report is read again: the 10th endorsement validates it on the server.
  Future<void> _onEndorsementToggled(
    IncidentEndorsementToggled event,
    Emitter<IncidentDetailState> emit,
  ) async {
    final incident = state.incident;
    final viewerId = state.viewerId;
    if (incident == null || viewerId == null || state.isEndorsing) return;

    final endorsed = incident.isEndorsedBy(viewerId);
    emit(state.copyWith(
      incident: endorsed ? incident.withoutEndorsementBy(viewerId) : incident.withEndorsementBy(viewerId),
      isEndorsing: true,
      clearEndorsementError: true,
    ));

    try {
      await _toggleEndorsement(incident: incident, userId: viewerId);
    } on Exception catch (e) {
      emit(state.copyWith(incident: incident, isEndorsing: false, endorsementError: _message(e)));
      return;
    }

    try {
      final fresh = await _getIncidentById(incident.id);
      emit(state.copyWith(incident: fresh, isEndorsing: false));
    } on Exception {
      // The endorsement is saved; keep the drawn copy until the next load.
      emit(state.copyWith(isEndorsing: false));
    }
  }

  /// Deletes the author's report (HU-18). The server has the last word: if the
  /// window closed meanwhile it refuses with a message, and the report is read
  /// again so the screen shows it frozen.
  Future<void> _onDeleteRequested(
    IncidentDeleteRequested event,
    Emitter<IncidentDetailState> emit,
  ) async {
    final incident = state.incident;
    final viewerId = state.viewerId;
    if (incident == null || viewerId == null || state.isDeleting || state.wasDeleted) return;

    emit(state.copyWith(isDeleting: true, clearDeleteError: true));
    try {
      await _deleteIncident(incident: incident, userId: viewerId);
    } on Exception catch (e) {
      emit(state.copyWith(isDeleting: false, deleteError: _message(e)));
      await _refresh(incident.id, emit);
      return;
    }
    emit(state.copyWith(isDeleting: false, wasDeleted: true));
  }

  /// Reads the report again, for example after the author edited it.
  Future<void> _onReloaded(IncidentReloaded event, Emitter<IncidentDetailState> emit) async {
    final incident = state.incident;
    if (incident == null) return;
    await _refresh(incident.id, emit);
  }

  Future<void> _refresh(String incidentId, Emitter<IncidentDetailState> emit) async {
    try {
      final fresh = await _getIncidentById(incidentId);
      emit(state.copyWith(incident: fresh));
    } on Exception {
      // Keep what is on screen; the next load will fix it.
    }
  }

  /// The signed-in citizen's id, or null for a guest or when the profile cannot be read.
  Future<String?> _viewerId() async {
    try {
      return (await _getCurrentProfile())?.id;
    } on Exception {
      return null;
    }
  }

  String _message(Exception e) => e.toString().replaceFirst('Exception: ', '').trim();
}

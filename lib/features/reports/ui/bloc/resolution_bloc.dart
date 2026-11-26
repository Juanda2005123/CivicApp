import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/usecases/get_current_profile_usecase.dart';
import '../../domain/entities/incident_resolution.dart';
import '../../domain/usecases/accept_resolution_usecase.dart';
import '../../domain/usecases/confirm_resolution_usecase.dart';
import '../../domain/usecases/get_active_resolution_usecase.dart';
import '../../domain/usecases/object_resolution_usecase.dart';
import '../../domain/usecases/pick_resolution_photo_usecase.dart';
import '../../domain/usecases/propose_resolution_usecase.dart';
import '../../domain/usecases/reject_resolution_usecase.dart';
import 'resolution_event.dart';
import 'resolution_state.dart';

/// Community resolution of a report (HU-25, RN-11): proposing the repair,
/// confirming or objecting as a neighbor, accepting or rejecting as the author.
/// The server applies the outcome; after every action the proposal is read
/// again and the detail is told to reload the report.
class ResolutionBloc extends Bloc<ResolutionEvent, ResolutionState> {
  final GetActiveResolutionUseCase _getActive;
  final PickResolutionPhotoUseCase _pickPhoto;
  final ProposeResolutionUseCase _propose;
  final ConfirmResolutionUseCase _confirm;
  final ObjectResolutionUseCase _object;
  final AcceptResolutionUseCase _accept;
  final RejectResolutionUseCase _reject;
  final GetCurrentProfileUseCase _getCurrentProfile;

  ResolutionBloc(
    this._getActive,
    this._pickPhoto,
    this._propose,
    this._confirm,
    this._object,
    this._accept,
    this._reject,
    this._getCurrentProfile,
  ) : super(const ResolutionState()) {
    on<ResolutionStarted>(_onStarted);
    on<ResolutionIncidentUpdated>(_onIncidentUpdated);
    on<ResolutionPhotoRequested>(_onPhotoRequested);
    on<ResolutionPhotoRemoved>(_onPhotoRemoved);
    on<ResolutionProposalSubmitted>(_onSubmitted);
    on<ResolutionConfirmed>(_onConfirmed);
    on<ResolutionObjected>(_onObjected);
    on<ResolutionAccepted>(_onAccepted);
    on<ResolutionRejected>(_onRejected);
  }

  Future<void> _onStarted(ResolutionStarted event, Emitter<ResolutionState> emit) async {
    emit(state.copyWith(
      status: ResolutionLoadStatus.loading,
      incident: event.incident,
      clearErrorMessage: true,
    ));
    try {
      final viewerId = await _viewerId();
      final resolution = await _getActive(event.incident.id);
      emit(ResolutionState(
        status: ResolutionLoadStatus.success,
        incident: event.incident,
        resolution: resolution,
        viewerId: viewerId,
        noticeCount: state.noticeCount,
        submittedCount: state.submittedCount,
        reportChangedCount: state.reportChangedCount,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(status: ResolutionLoadStatus.failure, errorMessage: _message(e)));
    }
  }

  void _onIncidentUpdated(ResolutionIncidentUpdated event, Emitter<ResolutionState> emit) {
    emit(state.copyWith(incident: event.incident));
  }

  Future<void> _onPhotoRequested(ResolutionPhotoRequested event, Emitter<ResolutionState> emit) async {
    if (state.isSubmitting) return;
    try {
      final photo = await _pickPhoto(fromCamera: event.fromCamera);
      if (photo == null) return;
      emit(state.copyWith(draftPhoto: photo, clearActionError: true));
    } on Exception catch (e) {
      emit(state.copyWith(actionError: _message(e)));
    }
  }

  void _onPhotoRemoved(ResolutionPhotoRemoved event, Emitter<ResolutionState> emit) {
    if (state.isSubmitting) return;
    emit(state.copyWith(removeDraftPhoto: true));
  }

  /// The author's own proposal closes the report (criterion 3); a neighbor's
  /// one is pinned for verification. When somebody else proposed first, the
  /// active proposal is shown so the citizen votes on it instead (criterion 2).
  Future<void> _onSubmitted(ResolutionProposalSubmitted event, Emitter<ResolutionState> emit) async {
    final incident = state.incident;
    final viewerId = state.viewerId;
    if (incident == null || viewerId == null || state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, clearActionError: true));
    try {
      final created = await _propose(
        incident: incident,
        userId: viewerId,
        photo: state.draftPhoto,
        description: event.description,
      );
      final closed = created.status.isApproved;
      emit(state.copyWith(
        isSubmitting: false,
        resolution: closed ? null : created,
        removeResolution: closed,
        removeDraftPhoto: true,
        submittedCount: state.submittedCount + 1,
        reportChangedCount: state.reportChangedCount + 1,
        notice: closed
            ? 'Listo: cerraste el reporte como reparado.'
            : 'Tu propuesta quedó en verificación. Con 3 confirmaciones de vecinos el reporte queda resuelto.',
        noticeCount: state.noticeCount + 1,
      ));
    } on Exception catch (e) {
      final active = await _readActive(incident.id);
      emit(state.copyWith(
        isSubmitting: false,
        resolution: active,
        actionError: _message(e),
        submittedCount: active == null ? null : state.submittedCount + 1,
      ));
    }
  }

  Future<void> _onConfirmed(ResolutionConfirmed event, Emitter<ResolutionState> emit) async {
    final resolution = state.resolution;
    final incident = state.incident;
    final viewerId = state.viewerId;
    if (resolution == null || incident == null || viewerId == null || state.isVoting) return;

    await _act(
      emit,
      () => _confirm(resolution: resolution, reporterId: incident.reporterId, userId: viewerId),
      done: 'Gracias, registramos tu confirmación.',
      closed: '¡Reparación verificada! El reporte quedó resuelto.',
    );
  }

  Future<void> _onObjected(ResolutionObjected event, Emitter<ResolutionState> emit) async {
    final resolution = state.resolution;
    final incident = state.incident;
    final viewerId = state.viewerId;
    if (resolution == null || incident == null || viewerId == null || state.isVoting) return;

    await _act(
      emit,
      () => _object(resolution: resolution, reporterId: incident.reporterId, userId: viewerId),
      done: 'Gracias, registramos tu objeción.',
      closed: 'La comunidad rechazó la propuesta. El reporte sigue abierto.',
    );
  }

  Future<void> _onAccepted(ResolutionAccepted event, Emitter<ResolutionState> emit) async {
    final resolution = state.resolution;
    final incident = state.incident;
    final viewerId = state.viewerId;
    if (resolution == null || incident == null || viewerId == null || state.isVoting) return;

    await _act(
      emit,
      () => _accept(resolution: resolution, reporterId: incident.reporterId, userId: viewerId),
      done: 'Aceptaste la reparación. El reporte quedó resuelto.',
      closed: 'Aceptaste la reparación. El reporte quedó resuelto.',
    );
  }

  Future<void> _onRejected(ResolutionRejected event, Emitter<ResolutionState> emit) async {
    final resolution = state.resolution;
    final incident = state.incident;
    final viewerId = state.viewerId;
    if (resolution == null || incident == null || viewerId == null || state.isVoting) return;

    await _act(
      emit,
      () => _reject(
        resolution: resolution,
        reporterId: incident.reporterId,
        userId: viewerId,
        reason: event.reason,
      ),
      done: 'Rechazaste la propuesta. El reporte sigue abierto.',
      closed: 'Rechazaste la propuesta. El reporte sigue abierto.',
    );
  }

  /// Runs a vote or a decision and reads the proposal again: when it is gone,
  /// the server decided it ([closed]) and the report must be reloaded.
  Future<void> _act(
    Emitter<ResolutionState> emit,
    Future<void> Function() action, {
    required String done,
    required String closed,
  }) async {
    final incidentId = state.incident!.id;
    emit(state.copyWith(isVoting: true, clearActionError: true));
    try {
      await action();
      final active = await _readActive(incidentId);
      final decided = active == null;
      emit(state.copyWith(
        isVoting: false,
        resolution: active,
        removeResolution: decided,
        notice: decided ? closed : done,
        noticeCount: state.noticeCount + 1,
        reportChangedCount: decided ? state.reportChangedCount + 1 : null,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(isVoting: false, actionError: _message(e)));
    }
  }

  /// The pending proposal, or the one on screen when it cannot be read.
  Future<IncidentResolution?> _readActive(String incidentId) async {
    try {
      return await _getActive(incidentId);
    } on Exception {
      return state.resolution;
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

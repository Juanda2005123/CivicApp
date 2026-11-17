import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_incident_by_id_usecase.dart';
import 'incident_detail_event.dart';
import 'incident_detail_state.dart';

class IncidentDetailBloc extends Bloc<IncidentDetailEvent, IncidentDetailState> {
  final GetIncidentByIdUseCase _getIncidentById;

  IncidentDetailBloc(this._getIncidentById) : super(const IncidentDetailState()) {
    on<IncidentDetailStarted>(_onIncidentDetailStarted);
  }

  Future<void> _onIncidentDetailStarted(
    IncidentDetailStarted event,
    Emitter<IncidentDetailState> emit,
  ) async {
    emit(state.copyWith(status: IncidentDetailStatus.loading, clearErrorMessage: true));
    try {
      final incident = await _getIncidentById(event.idOrTrackingCode);
      emit(state.copyWith(
        status: IncidentDetailStatus.success,
        incident: incident,
        clearErrorMessage: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: IncidentDetailStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', '').trim(),
      ));
    }
  }
}

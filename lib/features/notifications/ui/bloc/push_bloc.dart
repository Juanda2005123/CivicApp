import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/enable_push_usecase.dart';
import '../../domain/usecases/watch_opened_reports_usecase.dart';
import 'push_event.dart';
import 'push_state.dart';

/// Push notifications of the signed-in citizen (HU-24): turns them on when the
/// shell opens and reports every tapped push, so the screen opens that report.
class PushBloc extends Bloc<PushEvent, PushState> {
  final EnablePushUseCase _enable;
  final WatchOpenedReportsUseCase _watchOpened;

  PushBloc(this._enable, this._watchOpened) : super(const PushState()) {
    on<PushStarted>(_onStarted);
  }

  Future<void> _onStarted(PushStarted event, Emitter<PushState> emit) async {
    final enabled = await _enable();
    emit(state.copyWith(enabled: enabled));
    await emit.forEach<String>(
      _watchOpened(),
      onData: (id) => state.copyWith(openedIncidentId: id, openedCount: state.openedCount + 1),
    );
  }
}

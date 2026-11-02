import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_current_profile_usecase.dart';
import 'startup_event.dart';
import 'startup_state.dart';

/// Decides the first screen: the dashboard when a session is persisted and its
/// profile can be loaded, the login otherwise.
class StartupBloc extends Bloc<StartupEvent, StartupState> {
  final GetCurrentProfileUseCase _getCurrentProfile;

  StartupBloc(this._getCurrentProfile) : super(const StartupState()) {
    on<AppStarted>(_onStarted);
  }

  Future<void> _onStarted(AppStarted event, Emitter<StartupState> emit) async {
    try {
      final profile = await _getCurrentProfile();
      emit(state.copyWith(
        status: profile == null
            ? StartupStatus.unauthenticated
            : StartupStatus.authenticated,
      ));
    } on Exception {
      emit(state.copyWith(status: StartupStatus.unauthenticated));
    }
  }
}

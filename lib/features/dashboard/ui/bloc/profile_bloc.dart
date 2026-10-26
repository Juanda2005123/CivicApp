import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/usecases/get_current_profile_usecase.dart';
import '../../../auth/domain/usecases/sign_out_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// State of the profile summary screen (Sprint 1 dashboard).
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetCurrentProfileUseCase _getCurrentProfile;
  final SignOutUseCase _signOut;

  ProfileBloc(this._getCurrentProfile, this._signOut) : super(const ProfileState()) {
    on<ProfileStarted>(_onStarted);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onStarted(ProfileStarted event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileStatus.loading, clearErrorMessage: true));
    try {
      final profile = await _getCurrentProfile();
      if (profile == null) {
        emit(state.copyWith(status: ProfileStatus.signedOut));
        return;
      }
      emit(state.copyWith(status: ProfileStatus.success, profile: profile));
    } on Exception catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, errorMessage: _message(e)));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _signOut();
      emit(state.copyWith(status: ProfileStatus.signedOut));
    } on Exception catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, errorMessage: _message(e)));
    }
  }

  String _message(Exception e) => e.toString().replaceFirst('Exception: ', '');
}

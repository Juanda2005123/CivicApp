import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/profile.dart';
import '../../../auth/domain/usecases/get_current_profile_usecase.dart';
import '../../../auth/domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/get_civic_impact_usecase.dart';
import '../../domain/usecases/get_my_reports_usecase.dart';
import '../../domain/usecases/get_rank_progress_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

/// State of "Mi perfil": the profile summary (Sprint 1) and the civic impact
/// dashboard (HU-23): counters, progress to the next rank and "Mis reportes".
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetCurrentProfileUseCase _getCurrentProfile;
  final SignOutUseCase _signOut;
  final GetCivicImpactUseCase _getImpact;
  final GetRankProgressUseCase _getRankProgress;
  final GetMyReportsUseCase _getMyReports;

  /// A refresh is already running: another one would only repeat its requests.
  bool _refreshing = false;

  ProfileBloc(
    this._getCurrentProfile,
    this._signOut,
    this._getImpact,
    this._getRankProgress,
    this._getMyReports,
  ) : super(const ProfileState()) {
    on<ProfileStarted>(_onStarted);
    on<ProfileRefreshed>(_onRefreshed);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onStarted(ProfileStarted event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(status: ProfileStatus.loading, clearErrorMessage: true));
    try {
      final profile = await _getCurrentProfile();
      // No session: a guest browsing without an account (HU-22).
      if (profile == null) {
        emit(state.copyWith(status: ProfileStatus.guest));
        return;
      }
      emit(state.copyWith(
        status: ProfileStatus.success,
        profile: profile,
        impactStatus: ImpactStatus.loading,
        clearImpactErrorMessage: true,
      ));
      await _loadImpact(profile, emit);
    } on Exception catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, errorMessage: _message(e)));
    }
  }

  /// Reads everything again but keeps the screen as it is: the numbers change
  /// in place when the answer arrives, and a failure keeps the last ones.
  Future<void> _onRefreshed(ProfileRefreshed event, Emitter<ProfileState> emit) async {
    if (_refreshing || state.status == ProfileStatus.loading || state.status == ProfileStatus.guest) return;
    _refreshing = true;
    try {
      final profile = await _getCurrentProfile();
      if (profile == null) {
        emit(state.copyWith(status: ProfileStatus.guest));
        return;
      }
      emit(state.copyWith(status: ProfileStatus.success, profile: profile, clearErrorMessage: true));
      await _loadImpact(profile, emit);
    } on Exception catch (e) {
      // The citizen keeps what was on screen.
      emit(state.copyWith(impactStatus: _impactStatusAfterFailure(), impactErrorMessage: _message(e)));
    } finally {
      _refreshing = false;
    }
  }

  /// Counters, rank progress and own reports of [profile]. A failure here only
  /// marks the impact panel; the profile stays on screen.
  Future<void> _loadImpact(Profile profile, Emitter<ProfileState> emit) async {
    try {
      // The three reads run together; Future.wait rethrows the first real
      // exception, so the citizen reads its message.
      final impact = _getImpact(profile.id);
      final progress = _getRankProgress(profile.experiencePoints);
      final reports = _getMyReports(profile.id);
      await Future.wait<void>([impact, progress, reports]);
      emit(state.copyWith(
        impactStatus: ImpactStatus.success,
        impact: await impact,
        rankProgress: await progress,
        myReports: await reports,
        clearImpactErrorMessage: true,
      ));
    } on Exception catch (e) {
      emit(state.copyWith(impactStatus: _impactStatusAfterFailure(), impactErrorMessage: _message(e)));
    }
  }

  /// With numbers already drawn, a failed refresh keeps them as `success`; the
  /// first load that fails is a `failure` with a retry.
  ImpactStatus _impactStatusAfterFailure() =>
      state.impact == null ? ImpactStatus.failure : ImpactStatus.success;

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

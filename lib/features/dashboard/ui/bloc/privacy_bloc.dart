import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/usecases/update_privacy_usecase.dart';
import 'privacy_event.dart';
import 'privacy_state.dart';

/// Manages the citizen's privacy setting in "Configuración" (HU-01).
class PrivacyBloc extends Bloc<PrivacyEvent, PrivacyState> {
  final UpdatePrivacyUseCase _updatePrivacy;

  PrivacyBloc(this._updatePrivacy) : super(const PrivacyState()) {
    on<PrivacyStarted>(_onStarted);
    on<PrivacyToggled>(_onToggled);
  }

  void _onStarted(PrivacyStarted event, Emitter<PrivacyState> emit) {
    emit(state.copyWith(
      status: PrivacyStatus.initial,
      userId: event.userId,
      showRealName: event.showRealName,
      clearErrorMessage: true,
    ));
  }

  Future<void> _onToggled(PrivacyToggled event, Emitter<PrivacyState> emit) async {
    if (state.status == PrivacyStatus.saving || state.userId.isEmpty) return;
    final previousValue = state.showRealName;
    emit(state.copyWith(
      status: PrivacyStatus.saving,
      showRealName: event.showRealName,
      clearErrorMessage: true,
    ));
    try {
      await _updatePrivacy(userId: state.userId, showRealName: event.showRealName);
      emit(state.copyWith(status: PrivacyStatus.saved, showRealName: event.showRealName));
    } on Exception catch (e) {
      // Revert to the previous state when saving fails (HU-01, criterion 4).
      emit(state.copyWith(
        status: PrivacyStatus.failure,
        showRealName: previousValue,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}

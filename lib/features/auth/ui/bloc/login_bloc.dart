import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/sign_in_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final SignInUseCase _signIn;

  LoginBloc(this._signIn) : super(const LoginState()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: LoginStatus.loading, clearErrorMessage: true));
    try {
      final profile = await _signIn(email: event.email, password: event.password);
      emit(state.copyWith(status: LoginStatus.success, profile: profile));
    } on Exception catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}

enum StartupStatus { checking, authenticated, unauthenticated }

class StartupState {
  final StartupStatus status;

  const StartupState({this.status = StartupStatus.checking});

  StartupState copyWith({StartupStatus? status}) {
    return StartupState(status: status ?? this.status);
  }
}

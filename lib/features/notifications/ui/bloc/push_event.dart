import 'package:equatable/equatable.dart';

abstract class PushEvent extends Equatable {
  const PushEvent();

  @override
  List<Object?> get props => [];
}

/// The signed-in shell opened: turn on the citizen's pushes and listen to taps.
class PushStarted extends PushEvent {
  const PushStarted();
}

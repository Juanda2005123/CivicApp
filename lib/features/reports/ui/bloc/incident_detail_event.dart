import 'package:equatable/equatable.dart';

abstract class IncidentDetailEvent extends Equatable {
  const IncidentDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when an incident detail view opens with a given ID or tracking code.
class IncidentDetailStarted extends IncidentDetailEvent {
  final String idOrTrackingCode;

  const IncidentDetailStarted(this.idOrTrackingCode);

  @override
  List<Object?> get props => [idOrTrackingCode];
}

/// The citizen tapped "Apoyar" (or "Apoyado" to take the endorsement back) (HU-15).
class IncidentEndorsementToggled extends IncidentDetailEvent {
  const IncidentEndorsementToggled();
}

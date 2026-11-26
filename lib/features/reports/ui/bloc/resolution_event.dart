import 'package:equatable/equatable.dart';

import '../../domain/entities/incident.dart';

abstract class ResolutionEvent extends Equatable {
  const ResolutionEvent();

  @override
  List<Object?> get props => [];
}

/// The detail of a report opened: read its pending repair proposal (HU-25).
class ResolutionStarted extends ResolutionEvent {
  final Incident incident;

  const ResolutionStarted(this.incident);

  @override
  List<Object?> get props => [incident];
}

/// The report was read again (its status may have changed).
class ResolutionIncidentUpdated extends ResolutionEvent {
  final Incident incident;

  const ResolutionIncidentUpdated(this.incident);

  @override
  List<Object?> get props => [incident];
}

/// The citizen chose the repair photo, from the camera or the gallery.
class ResolutionPhotoRequested extends ResolutionEvent {
  final bool fromCamera;

  const ResolutionPhotoRequested({this.fromCamera = false});

  @override
  List<Object?> get props => [fromCamera];
}

/// The citizen took the repair photo off the proposal they are writing.
class ResolutionPhotoRemoved extends ResolutionEvent {
  const ResolutionPhotoRemoved();
}

/// The citizen sent "Reportar como reparado" with this description.
class ResolutionProposalSubmitted extends ResolutionEvent {
  final String description;

  const ResolutionProposalSubmitted(this.description);

  @override
  List<Object?> get props => [description];
}

/// A neighbor tapped "Confirmar reparación".
class ResolutionConfirmed extends ResolutionEvent {
  const ResolutionConfirmed();
}

/// A neighbor tapped "Objetar".
class ResolutionObjected extends ResolutionEvent {
  const ResolutionObjected();
}

/// The report author tapped "Aceptar".
class ResolutionAccepted extends ResolutionEvent {
  const ResolutionAccepted();
}

/// The report author rejected the proposal with this reason.
class ResolutionRejected extends ResolutionEvent {
  final String reason;

  const ResolutionRejected(this.reason);

  @override
  List<Object?> get props => [reason];
}

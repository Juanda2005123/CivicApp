import 'package:equatable/equatable.dart';

import '../../domain/entities/incident.dart';

abstract class EditReportEvent extends Equatable {
  const EditReportEvent();

  @override
  List<Object?> get props => [];
}

/// The edit screen opened with the report to change (HU-18).
class EditReportStarted extends EditReportEvent {
  final Incident incident;

  const EditReportStarted(this.incident);

  @override
  List<Object?> get props => [incident];
}

class EditCategorySelected extends EditReportEvent {
  final int categoryId;

  const EditCategorySelected(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class EditSeveritySelected extends EditReportEvent {
  final IncidentSeverity severity;

  const EditSeveritySelected(this.severity);

  @override
  List<Object?> get props => [severity];
}

/// The author removed one of the photos the report already has.
class EditKeptPhotoRemoved extends EditReportEvent {
  final String photoId;

  const EditKeptPhotoRemoved(this.photoId);

  @override
  List<Object?> get props => [photoId];
}

/// The author asked to add a photo, from the camera or the gallery.
class EditPhotoPickRequested extends EditReportEvent {
  final bool fromCamera;

  const EditPhotoPickRequested({required this.fromCamera});

  @override
  List<Object?> get props => [fromCamera];
}

/// The author removed a photo they had just added, by position.
class EditAddedPhotoRemoved extends EditReportEvent {
  final int index;

  const EditAddedPhotoRemoved(this.index);

  @override
  List<Object?> get props => [index];
}

/// The author tapped "Guardar cambios" with the text of the form.
class EditSubmitted extends EditReportEvent {
  final String title;
  final String description;
  final String? dimensions;

  const EditSubmitted({required this.title, required this.description, this.dimensions});

  @override
  List<Object?> get props => [title, description, dimensions];
}

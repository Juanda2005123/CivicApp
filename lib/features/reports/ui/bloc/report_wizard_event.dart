import 'package:equatable/equatable.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/picked_photo.dart';

abstract class ReportWizardEvent extends Equatable {
  const ReportWizardEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when the wizard screen opens to load categories.
class WizardStarted extends ReportWizardEvent {}

/// Fired when the citizen selects or confirms location in Step 1.
class LocationPitched extends ReportWizardEvent {
  final Coordinates coordinates;
  final String formattedAddress;
  final String neighborhood;
  final String city;

  const LocationPitched({
    required this.coordinates,
    required this.formattedAddress,
    required this.neighborhood,
    required this.city,
  });

  @override
  List<Object?> get props => [coordinates, formattedAddress, neighborhood, city];
}

/// Fired when category and severity are chosen in Step 2.
class CategoryAndSeveritySelected extends ReportWizardEvent {
  final int categoryId;
  final IncidentSeverity severity;

  const CategoryAndSeveritySelected({
    required this.categoryId,
    required this.severity,
  });

  @override
  List<Object?> get props => [categoryId, severity];
}

/// Fired when citizen confirms "Es este daño" on a nearby existing report (HU-09).
class NearbyReportEndorsed extends ReportWizardEvent {
  final String incidentId;

  const NearbyReportEndorsed(this.incidentId);

  @override
  List<Object?> get props => [incidentId];
}

/// Fired when citizen confirms "Es otro daño" to continue drafting their own report.
class NearbyCheckDismissed extends ReportWizardEvent {}

/// Fired when photo evidence is added, removed, or updated in Step 3.
class PhotosUpdated extends ReportWizardEvent {
  final List<PickedPhoto> photos;

  const PhotosUpdated(this.photos);

  @override
  List<Object?> get props => [photos];
}

/// Fired when text details (title, description, dimensions) are entered in Step 4.
class DetailsSubmitted extends ReportWizardEvent {
  final String title;
  final String description;
  final String? dimensions;

  const DetailsSubmitted({
    required this.title,
    required this.description,
    this.dimensions,
  });

  @override
  List<Object?> get props => [title, description, dimensions];
}

/// Fired when citizen explicitly switches between steps (1 to 5).
class StepNavigated extends ReportWizardEvent {
  final int targetStep;

  const StepNavigated(this.targetStep);

  @override
  List<Object?> get props => [targetStep];
}

/// Fired when the citizen confirms final publication in Step 5.
class ReportSubmitConfirmed extends ReportWizardEvent {}

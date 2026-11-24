import 'package:equatable/equatable.dart';

import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_category.dart';
import '../../domain/entities/incident_photo.dart';
import '../../domain/entities/picked_photo.dart';
import '../../domain/validators/report_validators.dart';

/// `loading`: reading the categories; `ready`: the form is editable;
/// `saving`: the request is in flight; `saved`: the screen closes with [savedIncident];
/// `failure`: the categories could not be read (nothing to edit with).
enum EditReportStatus { loading, ready, saving, saved, failure }

/// State of the edit form of a report (HU-18). A failed save goes back to
/// `ready` with the [errorMessage] and everything the author typed or picked.
class EditReportState extends Equatable {
  final EditReportStatus status;
  final Incident? incident;
  final List<IncidentCategory> categories;
  final int? categoryId;
  final IncidentSeverity severity;

  /// Photos the report already has and the author keeps.
  final List<IncidentPhoto> keptPhotos;

  /// Photos the author just picked, not uploaded yet.
  final List<PickedPhoto> addedPhotos;
  final String? errorMessage;
  final Incident? savedIncident;

  const EditReportState({
    this.status = EditReportStatus.loading,
    this.incident,
    this.categories = const [],
    this.categoryId,
    this.severity = IncidentSeverity.medium,
    this.keptPhotos = const [],
    this.addedPhotos = const [],
    this.errorMessage,
    this.savedIncident,
  });

  int get photoCount => keptPhotos.length + addedPhotos.length;

  bool get canAddPhoto => photoCount < ReportValidators.maxPhotosAllowed;

  EditReportState copyWith({
    EditReportStatus? status,
    Incident? incident,
    List<IncidentCategory>? categories,
    int? categoryId,
    IncidentSeverity? severity,
    List<IncidentPhoto>? keptPhotos,
    List<PickedPhoto>? addedPhotos,
    String? errorMessage,
    bool clearErrorMessage = false,
    Incident? savedIncident,
  }) {
    return EditReportState(
      status: status ?? this.status,
      incident: incident ?? this.incident,
      categories: categories ?? this.categories,
      categoryId: categoryId ?? this.categoryId,
      severity: severity ?? this.severity,
      keptPhotos: keptPhotos ?? this.keptPhotos,
      addedPhotos: addedPhotos ?? this.addedPhotos,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      savedIncident: savedIncident ?? this.savedIncident,
    );
  }

  @override
  List<Object?> get props => [
        status,
        incident,
        categories,
        categoryId,
        severity,
        keptPhotos,
        addedPhotos,
        errorMessage,
        savedIncident,
      ];
}

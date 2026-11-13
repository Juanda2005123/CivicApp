import 'package:equatable/equatable.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_category.dart';
import '../../domain/entities/nearby_incident.dart';
import '../../domain/entities/picked_photo.dart';

enum WizardStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

/// State representation for the 5-step report publication assistant.
class ReportWizardState extends Equatable {
  final WizardStatus status;
  final int currentStep; // 1 to 5
  final List<IncidentCategory> categories;
  final Coordinates? coordinates;
  final String? formattedAddress;
  final String? neighborhood;
  final String? city;
  final int? selectedCategoryId;
  final IncidentSeverity severity;
  final List<NearbyIncident> nearbyIncidents;
  final bool isCheckingNearby;
  final List<PickedPhoto> photos;
  final String title;
  final String description;
  final String? dimensions;
  final Incident? publishedIncident;
  final bool isEndorsedNearby;
  final String? errorMessage;

  const ReportWizardState({
    this.status = WizardStatus.initial,
    this.currentStep = 1,
    this.categories = const [],
    this.coordinates,
    this.formattedAddress,
    this.neighborhood,
    this.city,
    this.selectedCategoryId,
    this.severity = IncidentSeverity.medium,
    this.nearbyIncidents = const [],
    this.isCheckingNearby = false,
    this.photos = const [],
    this.title = '',
    this.description = '',
    this.dimensions,
    this.publishedIncident,
    this.isEndorsedNearby = false,
    this.errorMessage,
  });

  /// True if the citizen has entered any information into the draft.
  bool get hasDraftData =>
      coordinates != null ||
      selectedCategoryId != null ||
      photos.isNotEmpty ||
      title.trim().isNotEmpty ||
      description.trim().isNotEmpty;

  /// Returns the currently selected category object if found in the catalog.
  IncidentCategory? get selectedCategory {
    if (selectedCategoryId == null) return null;
    for (final cat in categories) {
      if (cat.id == selectedCategoryId) return cat;
    }
    return null;
  }

  ReportWizardState copyWith({
    WizardStatus? status,
    int? currentStep,
    List<IncidentCategory>? categories,
    Coordinates? coordinates,
    String? formattedAddress,
    String? neighborhood,
    String? city,
    int? selectedCategoryId,
    IncidentSeverity? severity,
    List<NearbyIncident>? nearbyIncidents,
    bool? isCheckingNearby,
    List<PickedPhoto>? photos,
    String? title,
    String? description,
    String? dimensions,
    Incident? publishedIncident,
    bool? isEndorsedNearby,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearPublishedIncident = false,
  }) {
    return ReportWizardState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      categories: categories ?? this.categories,
      coordinates: coordinates ?? this.coordinates,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      neighborhood: neighborhood ?? this.neighborhood,
      city: city ?? this.city,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      severity: severity ?? this.severity,
      nearbyIncidents: nearbyIncidents ?? this.nearbyIncidents,
      isCheckingNearby: isCheckingNearby ?? this.isCheckingNearby,
      photos: photos ?? this.photos,
      title: title ?? this.title,
      description: description ?? this.description,
      dimensions: dimensions ?? this.dimensions,
      publishedIncident: clearPublishedIncident ? null : (publishedIncident ?? this.publishedIncident),
      isEndorsedNearby: isEndorsedNearby ?? this.isEndorsedNearby,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentStep,
        categories,
        coordinates,
        formattedAddress,
        neighborhood,
        city,
        selectedCategoryId,
        severity,
        nearbyIncidents,
        isCheckingNearby,
        photos,
        title,
        description,
        dimensions,
        publishedIncident,
        isEndorsedNearby,
        errorMessage,
      ];
}

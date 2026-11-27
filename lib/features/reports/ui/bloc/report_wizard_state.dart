import 'package:equatable/equatable.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import '../../domain/entities/address_outcome.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_category.dart';
import '../../domain/entities/location_source.dart';
import '../../domain/entities/nearby_incident.dart';
import '../../domain/entities/picked_photo.dart';
import '../../domain/entities/suggested_address.dart';

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
  final bool isLocating;
  final String? locationStatusMessage;

  /// The user blocked the location permission; Step 1 offers to open the
  /// system settings.
  final bool isLocationBlocked;

  /// Address suggested from the GPS for Step 1 (HU-26). Cleared on every "Mi
  /// GPS" tap, so a new suggestion always reaches the form, even an equal one.
  final SuggestedAddress? suggestedAddress;

  /// The suggestion is still arriving: the cross street can take several
  /// seconds more than the rest of the address.
  final bool isSuggestingAddress;

  /// Why the suggestion is missing or incomplete, for the citizen to finish
  /// the address by hand. Null while it arrives and when it came complete.
  final String? addressSuggestionMessage;

  /// Where [coordinates] come from (HU-28). A GPS reading or a point confirmed
  /// on the map is the citizen's own decision and the typed address never moves
  /// it; the city center and a geocoded address are estimates.
  final LocationSource coordinatesSource;

  /// The typed address is being searched (HU-28): "Confirmar ubicación" shows
  /// the loading state and ignores taps.
  final bool isGeocodingAddress;

  /// How the last search of the typed address ended, to explain it in Step 1.
  /// Null until the first search and after the citizen picks the point (GPS or
  /// map).
  final AddressOutcome? addressOutcome;

  /// The address (with its neighborhood and city) the last settled search was
  /// for: confirming the same address again moves on to Step 2 instead of
  /// searching again. Null after a service failure, so retrying searches again.
  final String? geocodedAddressKey;
  final List<PickedPhoto> photos;
  final String title;
  final String description;
  final String? dimensions;
  final Incident? publishedIncident;
  final bool isEndorsedNearby;

  /// The citizen tapped "Es este" on a report they wrote: the wizard leaves without voting (HU-09, criterion 3).
  final bool isOwnNearbyReport;
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
    this.isLocating = false,
    this.locationStatusMessage,
    this.isLocationBlocked = false,
    this.suggestedAddress,
    this.isSuggestingAddress = false,
    this.addressSuggestionMessage,
    this.coordinatesSource = LocationSource.cityCenter,
    this.isGeocodingAddress = false,
    this.addressOutcome,
    this.geocodedAddressKey,
    this.photos = const [],
    this.title = '',
    this.description = '',
    this.dimensions,
    this.publishedIncident,
    this.isEndorsedNearby = false,
    this.isOwnNearbyReport = false,
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
    bool? isLocating,
    String? locationStatusMessage,
    bool clearLocationStatusMessage = false,
    bool? isLocationBlocked,
    SuggestedAddress? suggestedAddress,
    bool clearSuggestedAddress = false,
    bool? isSuggestingAddress,
    String? addressSuggestionMessage,
    bool clearAddressSuggestionMessage = false,
    LocationSource? coordinatesSource,
    bool? isGeocodingAddress,
    AddressOutcome? addressOutcome,
    bool clearAddressOutcome = false,
    String? geocodedAddressKey,
    bool clearGeocodedAddressKey = false,
    List<PickedPhoto>? photos,
    String? title,
    String? description,
    String? dimensions,
    Incident? publishedIncident,
    bool? isEndorsedNearby,
    bool? isOwnNearbyReport,
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
      isLocating: isLocating ?? this.isLocating,
      locationStatusMessage: clearLocationStatusMessage ? null : (locationStatusMessage ?? this.locationStatusMessage),
      isLocationBlocked: isLocationBlocked ?? this.isLocationBlocked,
      suggestedAddress: clearSuggestedAddress ? null : (suggestedAddress ?? this.suggestedAddress),
      isSuggestingAddress: isSuggestingAddress ?? this.isSuggestingAddress,
      addressSuggestionMessage:
          clearAddressSuggestionMessage ? null : (addressSuggestionMessage ?? this.addressSuggestionMessage),
      coordinatesSource: coordinatesSource ?? this.coordinatesSource,
      isGeocodingAddress: isGeocodingAddress ?? this.isGeocodingAddress,
      addressOutcome: clearAddressOutcome ? null : (addressOutcome ?? this.addressOutcome),
      geocodedAddressKey: clearGeocodedAddressKey ? null : (geocodedAddressKey ?? this.geocodedAddressKey),
      photos: photos ?? this.photos,
      title: title ?? this.title,
      description: description ?? this.description,
      dimensions: dimensions ?? this.dimensions,
      publishedIncident: clearPublishedIncident ? null : (publishedIncident ?? this.publishedIncident),
      isEndorsedNearby: isEndorsedNearby ?? this.isEndorsedNearby,
      isOwnNearbyReport: isOwnNearbyReport ?? this.isOwnNearbyReport,
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
        isLocating,
        locationStatusMessage,
        isLocationBlocked,
        suggestedAddress,
        isSuggestingAddress,
        addressSuggestionMessage,
        coordinatesSource,
        isGeocodingAddress,
        addressOutcome,
        geocodedAddressKey,
        photos,
        title,
        description,
        dimensions,
        publishedIncident,
        isEndorsedNearby,
        isOwnNearbyReport,
        errorMessage,
      ];
}

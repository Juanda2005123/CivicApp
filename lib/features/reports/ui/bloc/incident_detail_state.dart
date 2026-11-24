import 'package:equatable/equatable.dart';
import '../../domain/entities/incident.dart';

enum IncidentDetailStatus {
  initial,
  loading,
  success,
  failure,
}

/// State representation for the report detail screen (HU-14, HU-15, HU-16).
class IncidentDetailState extends Equatable {
  final IncidentDetailStatus status;
  final Incident? incident;
  final String? errorMessage;

  /// Id of the signed-in citizen, or null for a guest (HU-22) or while loading.
  /// Decides whether "Apoyar" opens the sign-in modal and whether it is hidden
  /// (the author never endorses their own report, RN-05).
  final String? viewerId;

  /// An endorsement request is in flight: the button ignores further taps.
  final bool isEndorsing;

  /// Why the last endorsement failed; the screen shows it once and the report
  /// goes back to how it was before the tap.
  final String? endorsementError;

  /// A delete request is in flight: the buttons ignore further taps (HU-18).
  final bool isDeleting;

  /// The report was deleted: the screen closes and tells the caller to reload.
  final bool wasDeleted;

  /// Why the last delete failed (for example the 30 minutes passed with the
  /// screen open); the screen shows it once (HU-18, criterion 5).
  final String? deleteError;

  const IncidentDetailState({
    this.status = IncidentDetailStatus.initial,
    this.incident,
    this.errorMessage,
    this.viewerId,
    this.isEndorsing = false,
    this.endorsementError,
    this.isDeleting = false,
    this.wasDeleted = false,
    this.deleteError,
  });

  bool get isGuest => viewerId == null;

  /// The signed-in citizen wrote this report.
  bool get viewerIsAuthor => incident != null && viewerId != null && incident!.reporterId == viewerId;

  /// The signed-in citizen has an active endorsement on this report.
  bool get viewerEndorsed => incident != null && viewerId != null && incident!.isEndorsedBy(viewerId!);

  IncidentDetailState copyWith({
    IncidentDetailStatus? status,
    Incident? incident,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? viewerId,
    bool? isEndorsing,
    String? endorsementError,
    bool clearEndorsementError = false,
    bool? isDeleting,
    bool? wasDeleted,
    String? deleteError,
    bool clearDeleteError = false,
  }) {
    return IncidentDetailState(
      status: status ?? this.status,
      incident: incident ?? this.incident,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      viewerId: viewerId ?? this.viewerId,
      isEndorsing: isEndorsing ?? this.isEndorsing,
      endorsementError: clearEndorsementError ? null : (endorsementError ?? this.endorsementError),
      isDeleting: isDeleting ?? this.isDeleting,
      wasDeleted: wasDeleted ?? this.wasDeleted,
      deleteError: clearDeleteError ? null : (deleteError ?? this.deleteError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        incident,
        errorMessage,
        viewerId,
        isEndorsing,
        endorsementError,
        isDeleting,
        wasDeleted,
        deleteError,
      ];
}

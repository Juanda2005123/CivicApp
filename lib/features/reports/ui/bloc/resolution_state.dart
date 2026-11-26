import 'package:equatable/equatable.dart';

import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_resolution.dart';
import '../../domain/entities/picked_photo.dart';

enum ResolutionLoadStatus { initial, loading, success, failure }

/// State of the community resolution of a report (HU-25, RN-11).
class ResolutionState extends Equatable {
  final ResolutionLoadStatus status;
  final Incident? incident;

  /// The pending proposal, or null when the report has none.
  final IncidentResolution? resolution;

  /// Id of the signed-in citizen, or null for a guest (HU-22).
  final String? viewerId;

  /// Repair photo of the proposal being written.
  final PickedPhoto? draftPhoto;

  /// A proposal is on its way: the button shows it and ignores taps.
  final bool isSubmitting;

  /// A vote or a decision is on its way.
  final bool isVoting;

  final String? errorMessage;

  /// Why the last action failed; the screen shows it once.
  final String? actionError;

  /// What the last action achieved; the screen shows it once per [noticeCount].
  final String? notice;
  final int noticeCount;

  /// Grows by one every time a proposal is sent: the form closes.
  final int submittedCount;

  /// Grows by one every time the status of the report may have changed: the
  /// detail reads the report again.
  final int reportChangedCount;

  const ResolutionState({
    this.status = ResolutionLoadStatus.initial,
    this.incident,
    this.resolution,
    this.viewerId,
    this.draftPhoto,
    this.isSubmitting = false,
    this.isVoting = false,
    this.errorMessage,
    this.actionError,
    this.notice,
    this.noticeCount = 0,
    this.submittedCount = 0,
    this.reportChangedCount = 0,
  });

  bool get isGuest => viewerId == null;

  bool get viewerIsAuthor => viewerId != null && viewerId == incident?.reporterId;

  bool get viewerIsProponent => viewerId != null && viewerId == resolution?.proponentId;

  bool get viewerHasVoted => viewerId != null && (resolution?.hasVoted(viewerId!) ?? false);

  /// "Reportar como reparado" is offered on an open report with no pending
  /// proposal (HU-25, criterion 1).
  bool get canPropose {
    final current = incident?.status;
    return resolution == null &&
        (current == IncidentStatus.reported ||
            current == IncidentStatus.communityValidated ||
            current == IncidentStatus.underReview);
  }

  ResolutionState copyWith({
    ResolutionLoadStatus? status,
    Incident? incident,
    IncidentResolution? resolution,
    bool removeResolution = false,
    String? viewerId,
    PickedPhoto? draftPhoto,
    bool removeDraftPhoto = false,
    bool? isSubmitting,
    bool? isVoting,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionError,
    bool clearActionError = false,
    String? notice,
    int? noticeCount,
    int? submittedCount,
    int? reportChangedCount,
  }) {
    return ResolutionState(
      status: status ?? this.status,
      incident: incident ?? this.incident,
      resolution: removeResolution ? null : (resolution ?? this.resolution),
      viewerId: viewerId ?? this.viewerId,
      draftPhoto: removeDraftPhoto ? null : (draftPhoto ?? this.draftPhoto),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isVoting: isVoting ?? this.isVoting,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      notice: notice ?? this.notice,
      noticeCount: noticeCount ?? this.noticeCount,
      submittedCount: submittedCount ?? this.submittedCount,
      reportChangedCount: reportChangedCount ?? this.reportChangedCount,
    );
  }

  @override
  List<Object?> get props => [
        status,
        incident,
        resolution,
        viewerId,
        draftPhoto,
        isSubmitting,
        isVoting,
        errorMessage,
        actionError,
        notice,
        noticeCount,
        submittedCount,
        reportChangedCount,
      ];
}

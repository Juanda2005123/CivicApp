import 'package:equatable/equatable.dart';

import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'incident_photo.dart';

/// Perceived severity level of the road hazard.
enum IncidentSeverity {
  low,
  medium,
  high,
  critical;

  String toDbValue() {
    switch (this) {
      case IncidentSeverity.low:
        return 'LOW';
      case IncidentSeverity.medium:
        return 'MEDIUM';
      case IncidentSeverity.high:
        return 'HIGH';
      case IncidentSeverity.critical:
        return 'CRITICAL';
    }
  }

  static IncidentSeverity fromDbValue(String value) {
    switch (value.toUpperCase()) {
      case 'LOW':
        return IncidentSeverity.low;
      case 'HIGH':
        return IncidentSeverity.high;
      case 'CRITICAL':
        return IncidentSeverity.critical;
      case 'MEDIUM':
      default:
        return IncidentSeverity.medium;
    }
  }

  String get labelSpanish {
    switch (this) {
      case IncidentSeverity.low:
        return 'Baja';
      case IncidentSeverity.medium:
        return 'Media';
      case IncidentSeverity.high:
        return 'Alta';
      case IncidentSeverity.critical:
        return 'Crítica';
    }
  }
}

/// Lifecycle status of an incident report.
enum IncidentStatus {
  reported,
  underReview,
  communityValidated,
  resolved;

  String toDbValue() {
    switch (this) {
      case IncidentStatus.reported:
        return 'REPORTED';
      case IncidentStatus.underReview:
        return 'UNDER_REVIEW';
      case IncidentStatus.communityValidated:
        return 'COMMUNITY_VALIDATED';
      case IncidentStatus.resolved:
        return 'RESOLVED';
    }
  }

  static IncidentStatus fromDbValue(String value) {
    switch (value.toUpperCase()) {
      case 'UNDER_REVIEW':
        return IncidentStatus.underReview;
      case 'COMMUNITY_VALIDATED':
        return IncidentStatus.communityValidated;
      case 'RESOLVED':
        return IncidentStatus.resolved;
      case 'REPORTED':
      default:
        return IncidentStatus.reported;
    }
  }

  String get labelSpanish {
    switch (this) {
      case IncidentStatus.reported:
        return 'Reportado';
      case IncidentStatus.underReview:
        return 'En revisión';
      case IncidentStatus.communityValidated:
        return 'Validado por la comunidad';
      case IncidentStatus.resolved:
        return 'Resuelto';
    }
  }
}

/// Core domain entity representing a public road damage report.
class Incident extends Equatable {
  final String id;
  final String trackingCode;
  final String reporterId;
  final String? reporterName;
  final String? reporterRankName;
  final int categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final String title;
  final String description;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String? estimatedDimensions;
  final Coordinates coordinates;
  final String formattedAddress;
  final String neighborhood;
  final String city;
  final List<IncidentPhoto> photos;
  final int upvotesCount;

  /// Ids of the citizens who endorsed the report; tells the viewer whether
  /// their own endorsement is active (HU-15).
  final List<String> upvoterIds;
  final int commentsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolverId;

  /// First time the report reached 10 endorsements (HU-16); never cleared.
  final DateTime? validatedAt;

  const Incident({
    required this.id,
    required this.trackingCode,
    required this.reporterId,
    this.reporterName,
    this.reporterRankName,
    required this.categoryId,
    this.categoryName,
    this.categoryIcon,
    required this.title,
    required this.description,
    required this.severity,
    this.status = IncidentStatus.reported,
    this.estimatedDimensions,
    required this.coordinates,
    required this.formattedAddress,
    required this.neighborhood,
    required this.city,
    this.photos = const [],
    this.upvotesCount = 0,
    this.upvoterIds = const [],
    this.commentsCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolverId,
    this.validatedAt,
  });

  /// Endorsements a report needs to be validated by the community (RN-08).
  static const int validationTarget = 10;

  /// How long after publishing the author may edit or delete the report (RN-03).
  static const Duration editWindow = Duration(minutes: 30);

  /// With this many endorsements the report is frozen for the author (RN-03).
  static const int editEndorsementLimit = 5;

  /// Moment the author's edit window closes.
  DateTime get editWindowEndsAt => createdAt.add(editWindow);

  /// Time left to edit or delete, never negative. Only a hint for the screen:
  /// the server decides with its own clock (HU-18, criterion 5).
  Duration editTimeLeft({DateTime? now}) {
    final left = editWindowEndsAt.difference(now ?? DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// The author may edit or delete only inside the window and with fewer than
  /// [editEndorsementLimit] endorsements; afterwards the report is frozen (RN-03, HU-18).
  bool canBeModifiedBy(String? userId, {DateTime? now}) {
    if (userId == null || userId != reporterId) return false;
    return editTimeLeft(now: now) > Duration.zero && upvotesCount < editEndorsementLimit;
  }

  /// True once the community validated the report: it stays true when later
  /// revocations bring the count under the target (HU-16, criterion 5).
  bool get isCommunityValidated => validatedAt != null || status == IncidentStatus.communityValidated;

  /// Endorsements still missing to reach [validationTarget], never negative.
  int get endorsementsMissing => (validationTarget - upvotesCount).clamp(0, validationTarget);

  /// Whether [userId] has an active endorsement on this report.
  bool isEndorsedBy(String userId) => upvoterIds.contains(userId);

  /// The same report with [userId]'s endorsement added; used to draw the tap
  /// before the server answers. The server decides validation, not this copy.
  Incident withEndorsementBy(String userId) {
    if (isEndorsedBy(userId)) return this;
    return copyWith(upvotesCount: upvotesCount + 1, upvoterIds: [...upvoterIds, userId]);
  }

  /// The same report with [userId]'s endorsement removed.
  Incident withoutEndorsementBy(String userId) {
    if (!isEndorsedBy(userId)) return this;
    return copyWith(
      upvotesCount: upvotesCount > 0 ? upvotesCount - 1 : 0,
      upvoterIds: upvoterIds.where((id) => id != userId).toList(),
    );
  }

  Incident copyWith({
    IncidentStatus? status,
    int? upvotesCount,
    List<String>? upvoterIds,
    DateTime? validatedAt,
    int? categoryId,
    String? categoryName,
    String? title,
    String? description,
    IncidentSeverity? severity,
    String? estimatedDimensions,
    bool clearEstimatedDimensions = false,
    List<IncidentPhoto>? photos,
  }) {
    return Incident(
      id: id,
      trackingCode: trackingCode,
      reporterId: reporterId,
      reporterName: reporterName,
      reporterRankName: reporterRankName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      estimatedDimensions: clearEstimatedDimensions ? null : (estimatedDimensions ?? this.estimatedDimensions),
      coordinates: coordinates,
      formattedAddress: formattedAddress,
      neighborhood: neighborhood,
      city: city,
      photos: photos ?? this.photos,
      upvotesCount: upvotesCount ?? this.upvotesCount,
      upvoterIds: upvoterIds ?? this.upvoterIds,
      commentsCount: commentsCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      resolvedAt: resolvedAt,
      resolverId: resolverId,
      validatedAt: validatedAt ?? this.validatedAt,
    );
  }

  IncidentPhoto? get primaryPhoto {
    for (final photo in photos) {
      if (photo.isPrimary) return photo;
    }
    return photos.isNotEmpty ? photos.first : null;
  }

  @override
  List<Object?> get props => [
        id,
        trackingCode,
        reporterId,
        reporterName,
        reporterRankName,
        categoryId,
        categoryName,
        categoryIcon,
        title,
        description,
        severity,
        status,
        estimatedDimensions,
        coordinates,
        formattedAddress,
        neighborhood,
        city,
        photos,
        upvotesCount,
        upvoterIds,
        commentsCount,
        createdAt,
        updatedAt,
        resolvedAt,
        resolverId,
        validatedAt,
      ];
}

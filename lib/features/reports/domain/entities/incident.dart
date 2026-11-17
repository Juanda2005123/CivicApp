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
  final int commentsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? resolverId;

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
    this.commentsCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.resolverId,
  });

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
        commentsCount,
        createdAt,
        updatedAt,
        resolvedAt,
        resolverId,
      ];
}

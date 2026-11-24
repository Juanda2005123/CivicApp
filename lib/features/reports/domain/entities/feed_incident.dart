import 'package:equatable/equatable.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

import 'incident.dart';

/// Summary of a report for a card of the community feed (HU-19): what the
/// card draws, without the description or the whole photo gallery that
/// [Incident] carries. The map uses the lighter `IncidentMarker`.
class FeedIncident extends Equatable {
  final String id;
  final String trackingCode;
  final String title;
  final String neighborhood;
  final String categoryName;

  /// What the author wrote, so the search of Comunidad can find it (HU-20).
  final String description;
  final String formattedAddress;

  /// Material icon key stored in `incident_category.icon` (e.g. `traffic`).
  /// The card draws it when the report has no photo.
  final String categoryIcon;
  final IncidentSeverity severity;
  final IncidentStatus status;

  /// Cover photo, or null when the report has none.
  final String? primaryPhotoUrl;
  final String? reporterName;
  final String? reporterRankName;

  /// `civic_rank.id_rank` of the author, 1 to 4 (RN-09): the level of the seal.
  /// Null when the author is unknown.
  final int? reporterRankId;
  final int upvotesCount;
  final int commentsCount;
  final Coordinates coordinates;
  final DateTime createdAt;

  const FeedIncident({
    required this.id,
    required this.trackingCode,
    required this.title,
    required this.neighborhood,
    required this.categoryName,
    this.description = '',
    this.formattedAddress = '',
    required this.categoryIcon,
    required this.severity,
    required this.status,
    this.primaryPhotoUrl,
    this.reporterName,
    this.reporterRankName,
    this.reporterRankId,
    this.upvotesCount = 0,
    this.commentsCount = 0,
    required this.coordinates,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        trackingCode,
        title,
        neighborhood,
        categoryName,
        description,
        formattedAddress,
        categoryIcon,
        severity,
        status,
        primaryPhotoUrl,
        reporterName,
        reporterRankName,
        reporterRankId,
        upvotesCount,
        commentsCount,
        coordinates,
        createdAt,
      ];
}

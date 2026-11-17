import 'package:equatable/equatable.dart';

/// Lightweight summary of an existing nearby report used for duplicate detection (HU-08/HU-09).
class NearbyIncident extends Equatable {
  final String id;
  final String trackingCode;
  final String title;
  final int categoryId;
  final String categoryName;
  final String severity;
  final double distanceInMeters;
  final String? primaryPhotoUrl;
  final int upvotesCount;

  const NearbyIncident({
    required this.id,
    required this.trackingCode,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.severity,
    required this.distanceInMeters,
    this.primaryPhotoUrl,
    this.upvotesCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        trackingCode,
        title,
        categoryId,
        categoryName,
        severity,
        distanceInMeters,
        primaryPhotoUrl,
        upvotesCount,
      ];
}

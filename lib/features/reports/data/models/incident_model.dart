import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import '../../domain/entities/incident.dart';
import 'incident_photo_model.dart';

/// DTO mapping a row of `road_incident` (joined with author, category, photos and upvotes)
/// to the [Incident] entity.
class IncidentModel extends Incident {
  const IncidentModel({
    required super.id,
    required super.trackingCode,
    required super.reporterId,
    super.reporterName,
    super.reporterRankName,
    required super.categoryId,
    super.categoryName,
    super.categoryIcon,
    required super.title,
    required super.description,
    required super.severity,
    super.status,
    super.estimatedDimensions,
    required super.coordinates,
    required super.formattedAddress,
    required super.neighborhood,
    required super.city,
    super.photos,
    super.upvotesCount,
    super.upvoterIds,
    super.commentsCount,
    required super.createdAt,
    super.updatedAt,
    super.resolvedAt,
    super.resolverId,
    super.validatedAt,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;

    final photosData = json['photos'] ?? json['incident_photo'];
    final photosList = (photosData as List<dynamic>?)
            ?.map((p) => IncidentPhotoModel.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    final upvotesList = json['incident_upvote'] as List<dynamic>?;
    final commentsList = json['incident_comment'] as List<dynamic>?;

    return IncidentModel(
      id: json['id_incident'] as String,
      trackingCode: json['tracking_code'] as String,
      reporterId: json['id_reporter_user'] as String,
      reporterName: (reporter == null || reporter['show_real_name'] == false)
          ? null
          : reporter['full_name'] as String?,
      reporterRankName: (reporter?['civic_rank'] as Map<String, dynamic>?)?['name'] as String?,
      categoryId: json['id_category'] as int,
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: IncidentSeverity.fromDbValue(json['severity'] as String? ?? 'MEDIUM'),
      status: IncidentStatus.fromDbValue(json['current_status'] as String? ?? 'REPORTED'),
      estimatedDimensions: json['estimated_dimensions'] as String?,
      coordinates: Coordinates(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      formattedAddress: json['formatted_address'] as String,
      neighborhood: json['neighborhood'] as String,
      city: (json['city'] as String?) ?? 'Cali',
      photos: photosList,
      upvotesCount: upvotesList?.length ?? (json['upvotes_count'] as int?) ?? 0,
      upvoterIds: upvotesList
              ?.map((u) => (u as Map<String, dynamic>)['id_user'] as String?)
              .whereType<String>()
              .toList() ??
          const [],
      commentsCount: commentsList?.length ?? (json['comments_count'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
      resolverId: json['id_resolver_user'] as String?,
      validatedAt: json['validated_at'] != null ? DateTime.parse(json['validated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      if (id.isNotEmpty) 'id_incident': id,
      'tracking_code': trackingCode,
      'id_reporter_user': reporterId,
      'id_category': categoryId,
      'title': title,
      'description': description,
      'severity': severity.toDbValue(),
      'current_status': status.toDbValue(),
      'estimated_dimensions': estimatedDimensions,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'formatted_address': formattedAddress,
      'neighborhood': neighborhood,
      'city': city,
    };
  }
}

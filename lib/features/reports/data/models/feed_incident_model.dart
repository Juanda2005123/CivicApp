import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

import '../../domain/entities/feed_incident.dart';
import '../../domain/entities/incident.dart';

/// Maps a row of `road_incident` selected for the community feed (HU-19) to
/// the [FeedIncident] entity. Column names live here and in the data source.
class FeedIncidentModel extends FeedIncident {
  const FeedIncidentModel({
    required super.id,
    required super.trackingCode,
    required super.title,
    required super.neighborhood,
    required super.categoryName,
    super.description,
    super.formattedAddress,
    required super.categoryIcon,
    required super.severity,
    required super.status,
    super.primaryPhotoUrl,
    super.reporterName,
    super.reporterRankName,
    super.reporterRankId,
    super.upvotesCount,
    super.commentsCount,
    required super.coordinates,
    required super.createdAt,
  });

  /// Columns the feed needs, nested as PostgREST resolves them.
  static const String select = 'id_incident, tracking_code, title, severity, current_status, '
      'neighborhood, description, formatted_address, latitude, longitude, created_at, '
      'category:incident_category(name, icon), '
      'reporter:user_profile!fk_incident_reporter_user(full_name, civic_rank(id_rank, name)), '
      'incident_photo(file_url, is_primary), incident_upvote(id_user), incident_comment(id_comment)';

  factory FeedIncidentModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final reporter = json['reporter'] as Map<String, dynamic>?;
    final rank = reporter?['civic_rank'] as Map<String, dynamic>?;
    final photos = (json['incident_photo'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [];
    final upvotes = json['incident_upvote'] as List<dynamic>?;
    final comments = json['incident_comment'] as List<dynamic>?;

    return FeedIncidentModel(
      id: json['id_incident'] as String,
      trackingCode: json['tracking_code'] as String,
      title: json['title'] as String,
      neighborhood: (json['neighborhood'] as String?) ?? '',
      categoryName: (category?['name'] as String?) ?? 'Otro daño vial',
      description: (json['description'] as String?) ?? '',
      formattedAddress: (json['formatted_address'] as String?) ?? '',
      categoryIcon: (category?['icon'] as String?) ?? 'more_horiz',
      severity: IncidentSeverity.fromDbValue((json['severity'] as String?) ?? 'MEDIUM'),
      status: IncidentStatus.fromDbValue((json['current_status'] as String?) ?? 'REPORTED'),
      primaryPhotoUrl: _coverUrl(photos),
      reporterName: reporter?['full_name'] as String?,
      reporterRankName: rank?['name'] as String?,
      reporterRankId: rank?['id_rank'] as int?,
      upvotesCount: upvotes?.length ?? 0,
      commentsCount: comments?.length ?? 0,
      coordinates: Coordinates(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// The photo flagged as primary, or the first one when none is.
  static String? _coverUrl(List<Map<String, dynamic>> photos) {
    if (photos.isEmpty) return null;
    final cover = photos.firstWhere((p) => p['is_primary'] == true, orElse: () => photos.first);
    return cover['file_url'] as String?;
  }
}

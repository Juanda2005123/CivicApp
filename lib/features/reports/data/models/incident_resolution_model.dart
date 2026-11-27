import '../../domain/entities/incident_resolution.dart';

/// DTO mapping a row of `incident_resolution` (joined with its proponent and its
/// votes) to the [IncidentResolution] entity.
class IncidentResolutionModel extends IncidentResolution {
  const IncidentResolutionModel({
    required super.id,
    required super.incidentId,
    required super.proponentId,
    super.proponentName,
    required super.photoUrl,
    required super.description,
    super.status,
    super.confirmerIds,
    super.objectorIds,
    required super.proposedAt,
    super.resolvedAt,
    super.rejectionReason,
  });

  factory IncidentResolutionModel.fromJson(Map<String, dynamic> json) {
    final proponent = json['proponent'] as Map<String, dynamic>?;
    final resolvedAt = json['resolved_at'] as String?;

    return IncidentResolutionModel(
      id: json['id_resolution'] as String,
      incidentId: json['id_incident'] as String,
      proponentId: json['id_proponent_user'] as String,
      proponentName: (proponent == null || proponent['show_real_name'] == false)
          ? null
          : proponent['full_name'] as String?,
      photoUrl: (json['photo_evidence_url'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      status: ResolutionStatus.fromDbValue((json['status'] as String?) ?? 'PENDING'),
      confirmerIds: _userIds(json['resolution_confirmation']),
      objectorIds: _userIds(json['resolution_objection']),
      proposedAt: DateTime.parse(json['proposed_at'] as String),
      resolvedAt: resolvedAt == null ? null : DateTime.parse(resolvedAt),
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  /// The votes come as a list of `{id_user}` rows; a fresh insert has none.
  static List<String> _userIds(Object? rows) {
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map((row) => row['id_user'] as String?)
        .whereType<String>()
        .toList();
  }
}

import '../../domain/entities/incident_photo.dart';

/// DTO mapping a row of `incident_photo` to the [IncidentPhoto] entity.
class IncidentPhotoModel extends IncidentPhoto {
  const IncidentPhotoModel({
    required super.id,
    required super.incidentId,
    required super.fileUrl,
    super.isPrimary,
    required super.uploadedAt,
  });

  factory IncidentPhotoModel.fromJson(Map<String, dynamic> json) {
    return IncidentPhotoModel(
      id: json['id_photo'] as String,
      incidentId: json['id_incident'] as String,
      fileUrl: json['file_url'] as String,
      isPrimary: (json['is_primary'] as bool?) ?? false,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_photo': id,
      'id_incident': incidentId,
      'file_url': fileUrl,
      'is_primary': isPrimary,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}

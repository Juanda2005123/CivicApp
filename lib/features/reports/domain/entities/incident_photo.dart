import 'package:equatable/equatable.dart';

/// Photographic evidence record attached to a road incident.
class IncidentPhoto extends Equatable {
  final String id;
  final String incidentId;
  final String fileUrl;
  final bool isPrimary;
  final DateTime uploadedAt;

  const IncidentPhoto({
    required this.id,
    required this.incidentId,
    required this.fileUrl,
    this.isPrimary = false,
    required this.uploadedAt,
  });

  @override
  List<Object?> get props => [id, incidentId, fileUrl, isPrimary, uploadedAt];
}

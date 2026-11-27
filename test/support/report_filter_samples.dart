import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_marker.dart';

/// A report of the Comunidad feed with the text a search can match (HU-20).
FeedIncident filterFeedIncident({
  String id = 'inc-1',
  String code = '#VIG-1001',
  String title = 'Hueco profundo',
  String description = 'Cráter en el carril derecho.',
  String address = 'Calle 5 # 38-20',
  String neighborhood = 'San Fernando',
  String category = 'Hueco o bache en calzada',
  int upvotes = 0,
  DateTime? createdAt,
  Coordinates coordinates = const Coordinates(latitude: 3.4516, longitude: -76.5320),
}) {
  return FeedIncident(
    id: id,
    trackingCode: code,
    title: title,
    description: description,
    formattedAddress: address,
    neighborhood: neighborhood,
    categoryName: category,
    categoryIcon: 'traffic',
    severity: IncidentSeverity.high,
    status: IncidentStatus.reported,
    upvotesCount: upvotes,
    coordinates: coordinates,
    createdAt: createdAt ?? DateTime(2026, 11, 12),
  );
}

/// A map marker with the same searchable fields.
IncidentMarker filterMarker({
  String id = 'inc-1',
  String code = '#VIG-1001',
  String title = 'Hueco profundo',
  String description = 'Cráter en el carril derecho.',
  String address = 'Calle 5 # 38-20',
  String neighborhood = 'San Fernando',
  String category = 'Hueco o bache en calzada',
}) {
  return IncidentMarker(
    id: id,
    trackingCode: code,
    title: title,
    description: description,
    formattedAddress: address,
    neighborhood: neighborhood,
    categoryName: category,
    categoryIcon: 'traffic',
    severity: IncidentSeverity.high,
    coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
  );
}

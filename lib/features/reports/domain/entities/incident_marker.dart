import 'package:equatable/equatable.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

import 'incident.dart';

/// Lightweight summary of a report, just what the map needs to draw its
/// marker (HU-13).
class IncidentMarker extends Equatable {
  final String id;
  final String trackingCode;
  final String title;
  final String categoryName;

  /// Material icon key stored in `incident_category.icon` (e.g. `traffic`).
  final String categoryIcon;
  final IncidentSeverity severity;
  final Coordinates coordinates;

  const IncidentMarker({
    required this.id,
    required this.trackingCode,
    required this.title,
    required this.categoryName,
    required this.categoryIcon,
    required this.severity,
    required this.coordinates,
  });

  @override
  List<Object?> get props => [id, trackingCode, title, categoryName, categoryIcon, severity, coordinates];
}

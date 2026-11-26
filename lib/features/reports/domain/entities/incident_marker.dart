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

  /// The place and the text of the report, so the filters of Comunidad also
  /// narrow the map (HU-20, criterion 5).
  final String neighborhood;
  final String description;
  final String formattedAddress;

  /// Material icon key stored in `incident_category.icon` (e.g. `traffic`).
  final String categoryIcon;
  final IncidentSeverity severity;
  final Coordinates coordinates;

  /// Lifecycle status; the map leaves resolved reports out (HU-25).
  final IncidentStatus status;

  const IncidentMarker({
    required this.id,
    required this.trackingCode,
    required this.title,
    required this.categoryName,
    this.neighborhood = '',
    this.description = '',
    this.formattedAddress = '',
    required this.categoryIcon,
    required this.severity,
    required this.coordinates,
    this.status = IncidentStatus.reported,
  });

  @override
  List<Object?> get props => [
        id,
        trackingCode,
        title,
        categoryName,
        neighborhood,
        description,
        formattedAddress,
        categoryIcon,
        severity,
        coordinates,
        status,
      ];
}

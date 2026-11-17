import 'package:equatable/equatable.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

/// What the reverse geocoding service knows about a point, as raw text
/// (HU-26). The use case turns it into a [SuggestedAddress].
class GeocodedPlace extends Equatable {
  /// Street name, e.g. `Calle 12` or `Carrera 9 Norte`.
  final String? road;

  /// Colombian plate, e.g. `5-37` (cross street 5, number 37). Often missing.
  final String? houseNumber;
  final String? neighborhood;

  /// The street's line when the service returns it (street-level answers);
  /// its vertices are usually the corners. Empty otherwise.
  final List<Coordinates> roadPath;

  const GeocodedPlace({this.road, this.houseNumber, this.neighborhood, this.roadPath = const []});

  @override
  List<Object?> get props => [road, houseNumber, neighborhood, roadPath.length];
}

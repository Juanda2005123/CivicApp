import 'package:equatable/equatable.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

/// What the geocoding service found for a typed address (HU-28).
class AddressMatch extends Equatable {
  final Coordinates coordinates;

  /// True when the service located the street but not the door: the point is
  /// somewhere along the road, usually a few hundred meters from the damage.
  final bool isStreetOnly;

  const AddressMatch({required this.coordinates, required this.isStreetOnly});

  @override
  List<Object?> get props => [coordinates.latitude, coordinates.longitude, isStreetOnly];
}

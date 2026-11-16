import 'package:equatable/equatable.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

import 'address_outcome.dart';
import 'location_source.dart';

/// The point a typed address was turned into (HU-28), and how the search ended.
/// When the address was not located the point is the city center.
class ResolvedLocation extends Equatable {
  final Coordinates coordinates;
  final AddressOutcome outcome;

  const ResolvedLocation({required this.coordinates, required this.outcome});

  /// [LocationSource.address] when the search located it, else the city center.
  LocationSource get source => outcome.isFound ? LocationSource.address : LocationSource.cityCenter;

  /// True when the address was not found and the point is only the city center.
  bool get isCityCenter => !outcome.isFound;

  @override
  List<Object?> get props => [coordinates.latitude, coordinates.longitude, outcome];
}

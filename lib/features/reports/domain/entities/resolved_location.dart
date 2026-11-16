import 'package:equatable/equatable.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

import 'location_source.dart';

/// The point a typed address was turned into (HU-28), and how it was found:
/// [LocationSource.address] when the service located it, or
/// [LocationSource.cityCenter] when it did not and the city center stands in.
class ResolvedLocation extends Equatable {
  final Coordinates coordinates;
  final LocationSource source;

  const ResolvedLocation({required this.coordinates, required this.source});

  /// True when the address was not found and the point is only the city center.
  bool get isCityCenter => source == LocationSource.cityCenter;

  @override
  List<Object?> get props => [coordinates.latitude, coordinates.longitude, source];
}

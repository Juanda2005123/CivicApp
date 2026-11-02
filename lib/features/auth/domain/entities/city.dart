import 'package:equatable/equatable.dart';

/// How a city takes part in the conurbation resolution of the GPS detector.
enum CityKind { independent, capital, satellite }

/// Official coverage city of VIGÍA (DANE catalog, business rule RN-12).
///
/// [radiusKm] is only set for capitals and satellites of a conurbation: it is
/// the calibrated radius used by the nearest-city detection.
class City extends Equatable {
  final int id;
  final String name;
  final String department;
  final double latitude;
  final double longitude;
  final bool isCapital;
  final CityKind kind;
  final double? radiusKm;

  const City({
    required this.id,
    required this.name,
    required this.department,
    required this.latitude,
    required this.longitude,
    required this.isCapital,
    this.kind = CityKind.independent,
    this.radiusKm,
  });

  String get displayName => '$name ($department)';

  @override
  List<Object?> get props => [id, name, department];
}

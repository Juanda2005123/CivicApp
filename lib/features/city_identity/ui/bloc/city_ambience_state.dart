import 'package:equatable/equatable.dart';

import '../../domain/entities/city_identity.dart';
import '../../domain/entities/day_part.dart';

/// The look the whole app wears. One state with `copyWith`: the last look stays
/// on screen while anything else changes.
class CityAmbienceState extends Equatable {
  /// Pack of the city being looked at.
  final CityIdentity identity;

  /// Pack of the citizen's own city, or null while it is unknown.
  final CityIdentity? reference;

  /// The cities with their own pack.
  final List<CityIdentity> featured;

  final DayPart dayPart;

  /// Counts the moves from one city to another; each one draws the curtain.
  final int citySwitches;

  /// The current [identity] arrived by such a move: the theme changes behind the
  /// curtain.
  final bool arrivedBySwitch;

  const CityAmbienceState({
    required this.identity,
    required this.dayPart,
    this.reference,
    this.featured = const [],
    this.citySwitches = 0,
    this.arrivedBySwitch = false,
  });

  CityAmbienceState copyWith({
    CityIdentity? identity,
    CityIdentity? reference,
    DayPart? dayPart,
    int? citySwitches,
    bool? arrivedBySwitch,
  }) {
    return CityAmbienceState(
      identity: identity ?? this.identity,
      reference: reference ?? this.reference,
      featured: featured,
      dayPart: dayPart ?? this.dayPart,
      citySwitches: citySwitches ?? this.citySwitches,
      arrivedBySwitch: arrivedBySwitch ?? this.arrivedBySwitch,
    );
  }

  @override
  List<Object?> get props => [identity, reference, featured, dayPart, citySwitches, arrivedBySwitch];
}

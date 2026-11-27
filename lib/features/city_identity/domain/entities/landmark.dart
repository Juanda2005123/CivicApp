import 'package:equatable/equatable.dart';

import 'city_photo.dart';

/// The place a city gives to one civic rank: the steps of the "climb" of a
/// citizen. The rank thresholds are not here, they come from the database.
class Landmark extends Equatable {
  /// Name of the rank it stands for (`civic_rank.name`).
  final String rankName;

  /// Name of the place ("La Ermita"). The generic looks reuse the rank name.
  final String title;

  /// Null in the looks without photos: the rank seal is drawn instead.
  final CityPhoto? photo;

  const Landmark({required this.rankName, required this.title, this.photo});

  @override
  List<Object?> get props => [rankName, title, photo];
}

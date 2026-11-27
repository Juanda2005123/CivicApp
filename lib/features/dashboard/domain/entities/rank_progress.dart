import 'package:equatable/equatable.dart';

import 'rank_level.dart';

/// Where a citizen stands on the civic ladder: the current rank, the next one
/// and how far along the bar is (HU-23, criteria 3 and 4).
class RankProgress extends Equatable {
  final RankLevel current;

  /// The next rank, or null when [current] is the highest one.
  final RankLevel? next;
  final int experiencePoints;

  /// The whole ladder, lowest rank first, to draw every step. It is not part of
  /// equality: two citizens stand in the same place whatever the list holds.
  final List<RankLevel> ladder;

  const RankProgress({
    required this.current,
    required this.next,
    required this.experiencePoints,
    this.ladder = const [],
  });

  /// The citizen reached the highest oversight milestone.
  bool get isMaxRank => next == null;

  /// Points still missing for the next rank; 0 at the highest rank.
  int get xpMissing => next == null ? 0 : (next!.minXp - experiencePoints).clamp(0, next!.minXp);

  /// Share of the way from [current] to [next], between 0 and 1. A full bar at
  /// the highest rank.
  double get fraction {
    final upper = next;
    if (upper == null) return 1;
    final span = upper.minXp - current.minXp;
    if (span <= 0) return 1;
    return ((experiencePoints - current.minXp) / span).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [current, next, experiencePoints];
}

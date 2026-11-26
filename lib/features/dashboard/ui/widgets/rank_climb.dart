import 'package:flutter/material.dart';

import '../../../../core/widgets/city/landmark_trail.dart';
import '../../domain/entities/rank_level.dart';
import '../../domain/entities/rank_progress.dart';

/// Progress toward the next civic rank (HU-23, criteria 3 and 4), drawn as the
/// climb through the places of the citizen's city: the points, the bar and a
/// sentence that says what is missing. At the highest rank the bar is full and
/// the sentence says so.
class RankClimb extends StatelessWidget {
  final RankProgress progress;

  /// Put on the medal of the current rank, where the rank celebration opens.
  final Key? currentMedalKey;

  const RankClimb({super.key, required this.progress, this.currentMedalKey});

  static TrailRank trailRankOf(RankLevel rank) => TrailRank(level: rank.id, name: rank.name, minXp: rank.minXp);

  @override
  Widget build(BuildContext context) {
    final next = progress.next;
    final caption = next == null
        ? 'Llegaste al nivel más alto. Gracias por vigilar tu ciudad.'
        : 'Te faltan ${progress.xpMissing} pts para el Nivel ${next.id} · ${next.name}.';
    final points =
        next == null ? '${progress.experiencePoints} pts' : '${progress.experiencePoints} / ${next.minXp} pts';
    final ladder = progress.ladder.isEmpty ? [progress.current, ?next] : progress.ladder;

    return LandmarkTrail(
      ranks: [for (final rank in ladder) trailRankOf(rank)],
      currentLevel: progress.current.id,
      title: 'Tu avance',
      progress: progress.fraction,
      points: points,
      caption: caption,
      currentMedalKey: currentMedalKey,
    );
  }
}

import '../entities/rank_level.dart';
import '../entities/rank_progress.dart';
import '../repositories/impact_repository.dart';

/// Places the experience points of a citizen on the civic ladder (RN-09,
/// HU-23 criteria 3 and 4). The thresholds come from the database, so the rank
/// shown is always the one the server computed from the same points.
class GetRankProgressUseCase {
  final ImpactRepository _repository;

  GetRankProgressUseCase(this._repository);

  Future<RankProgress> call(int experiencePoints) async {
    final ranks = [...await _repository.getRanks()]..sort((a, b) => a.minXp.compareTo(b.minXp));
    if (ranks.isEmpty) throw Exception('No pudimos cargar los niveles cívicos.');

    var current = ranks.first;
    RankLevel? next;
    for (final rank in ranks) {
      if (rank.minXp <= experiencePoints) {
        current = rank;
      } else {
        next = rank;
        break;
      }
    }
    return RankProgress(current: current, next: next, experiencePoints: experiencePoints, ladder: ranks);
  }
}

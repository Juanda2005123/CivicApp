import 'package:vigia_app/features/dashboard/domain/entities/civic_impact.dart';
import 'package:vigia_app/features/dashboard/domain/entities/rank_level.dart';
import 'package:vigia_app/features/dashboard/domain/repositories/impact_repository.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';

/// The civic ladder the database seeds (RN-09): 0, 1000, 2500 and 4000 XP.
const defaultRanks = [
  RankLevel(id: 1, name: 'Observador Urbano', minXp: 0),
  RankLevel(id: 2, name: 'Vecino Vigilante', minXp: 1000),
  RankLevel(id: 3, name: 'Guardián Cívico', minXp: 2500),
  RankLevel(id: 4, name: 'Veedor Mayor', minXp: 4000),
];

/// In-memory [ImpactRepository] that records its calls.
class FakeImpactRepository implements ImpactRepository {
  final List<String> calls = [];
  CivicImpact impact = const CivicImpact();
  List<RankLevel> ranks = defaultRanks;
  List<FeedIncident> myReports = [];
  Exception? impactError;
  Exception? ranksError;
  Exception? reportsError;

  @override
  Future<CivicImpact> getImpact(String userId) async {
    calls.add('impact.get:$userId');
    if (impactError != null) throw impactError!;
    return impact;
  }

  @override
  Future<List<RankLevel>> getRanks() async {
    calls.add('impact.ranks');
    if (ranksError != null) throw ranksError!;
    return ranks;
  }

  @override
  Future<List<FeedIncident>> getMyReports(String userId) async {
    calls.add('impact.reports:$userId');
    if (reportsError != null) throw reportsError!;
    return myReports;
  }
}

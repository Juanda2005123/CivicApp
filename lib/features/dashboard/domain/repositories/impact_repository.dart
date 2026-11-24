import '../../../reports/domain/entities/feed_incident.dart';
import '../entities/civic_impact.dart';
import '../entities/rank_level.dart';

/// What the civic impact dashboard needs to read (HU-23).
abstract class ImpactRepository {
  /// The four counters of [userId], computed from their actual activity.
  Future<CivicImpact> getImpact(String userId);

  /// The whole civic ladder, lowest rank first.
  Future<List<RankLevel>> getRanks();

  /// Reports published by [userId], newest first.
  Future<List<FeedIncident>> getMyReports(String userId);
}

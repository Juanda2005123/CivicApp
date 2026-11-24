import '../../../reports/domain/entities/feed_incident.dart';
import '../../domain/entities/civic_impact.dart';
import '../../domain/entities/rank_level.dart';
import '../../domain/repositories/impact_repository.dart';
import '../datasources/impact_remote_data_source.dart';

class ImpactRepositoryImpl implements ImpactRepository {
  final ImpactRemoteDataSource _dataSource;

  ImpactRepositoryImpl(this._dataSource);

  @override
  Future<CivicImpact> getImpact(String userId) => _dataSource.getImpact(userId);

  @override
  Future<List<RankLevel>> getRanks() => _dataSource.getRanks();

  @override
  Future<List<FeedIncident>> getMyReports(String userId) => _dataSource.getMyReports(userId);
}

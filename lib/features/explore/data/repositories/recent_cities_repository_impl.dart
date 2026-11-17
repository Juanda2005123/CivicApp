import '../../domain/repositories/recent_cities_repository.dart';
import '../datasources/recent_cities_local_data_source.dart';

class RecentCitiesRepositoryImpl implements RecentCitiesRepository {
  final RecentCitiesLocalDataSource _dataSource;

  RecentCitiesRepositoryImpl(this._dataSource);

  @override
  Future<List<String>> getRecentNames() => _dataSource.getRecentNames();

  @override
  Future<void> saveRecentNames(List<String> names) => _dataSource.saveRecentNames(names);
}

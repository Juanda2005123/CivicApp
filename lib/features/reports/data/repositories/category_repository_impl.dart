import '../../domain/entities/incident_category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_remote_data_source.dart';

/// Implements [CategoryRepository] delegating to [CategoryRemoteDataSource].
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource _dataSource;

  CategoryRepositoryImpl(this._dataSource);

  @override
  Future<List<IncidentCategory>> getCategories() {
    return _dataSource.getCategories();
  }
}

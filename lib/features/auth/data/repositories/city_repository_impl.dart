import '../../domain/entities/city.dart';
import '../../domain/repositories/city_repository.dart';
import '../datasources/city_remote_data_source.dart';

/// Concrete implementation of CityRepository interacting with CityRemoteDataSource.
class CityRepositoryImpl implements CityRepository {
  final CityRemoteDataSource remoteDataSource;

  CityRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<City>> getCities() async {
    return await remoteDataSource.getCities();
  }
}

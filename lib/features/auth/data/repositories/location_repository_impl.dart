import '../../domain/entities/coordinates.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource _dataSource;

  LocationRepositoryImpl(this._dataSource);

  @override
  Future<Coordinates> currentCoordinates({bool askPermission = true}) =>
      _dataSource.currentCoordinates(askPermission: askPermission);

  @override
  Future<bool> openSettings() => _dataSource.openSettings();
}

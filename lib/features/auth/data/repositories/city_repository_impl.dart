import 'package:flutter/foundation.dart';

import '../../domain/entities/city.dart';
import '../../domain/repositories/city_repository.dart';
import '../datasources/city_local_data_source.dart';
import '../datasources/city_remote_data_source.dart';

/// Combines two sources: the remote `coverage_city` table is the catalog of
/// record; the embedded copy supplies the conurbation calibration (which the
/// table does not store) and is the fallback when the table cannot be read.
class CityRepositoryImpl implements CityRepository {
  final CityRemoteDataSource _remote;
  final CityLocalDataSource _local;

  CityRepositoryImpl(this._remote, this._local);

  @override
  Future<List<City>> getCities() async {
    final calibrated = _local.getCities();
    try {
      final remote = await _remote.getCities();
      if (remote.isNotEmpty) {
        return remote.map((city) => _withCalibration(city, calibrated)).toList();
      }
    } on Exception catch (e) {
      debugPrint('Coverage cities unavailable remotely, using the local catalog: $e');
    }
    return calibrated;
  }

  City _withCalibration(City city, List<City> calibrated) {
    for (final known in calibrated) {
      if (known.name == city.name && known.department == city.department) {
        return City(
          id: city.id,
          name: city.name,
          department: city.department,
          latitude: city.latitude,
          longitude: city.longitude,
          isCapital: city.isCapital,
          kind: known.kind,
          radiusKm: known.radiusKm,
        );
      }
    }
    return city;
  }
}

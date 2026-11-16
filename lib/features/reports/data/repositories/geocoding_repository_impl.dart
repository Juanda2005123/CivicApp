import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

import '../../domain/entities/geocoded_place.dart';
import '../../domain/repositories/geocoding_repository.dart';
import '../datasources/nominatim_data_source.dart';

/// Implements [GeocodingRepository] by delegating to Nominatim.
class GeocodingRepositoryImpl implements GeocodingRepository {
  final NominatimDataSource _dataSource;

  GeocodingRepositoryImpl(this._dataSource);

  @override
  Future<GeocodedPlace> reverseGeocode(Coordinates coordinates) => _dataSource.reverseGeocode(coordinates);

  @override
  Future<GeocodedPlace> streetAt(Coordinates coordinates) => _dataSource.streetAt(coordinates);

  @override
  Future<Coordinates> geocodeAddress(String query) => _dataSource.search(query);
}

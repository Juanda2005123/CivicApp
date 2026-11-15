import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/city_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/detect_nearest_city_usecase.dart';

import '../entities/incident_marker.dart';
import '../repositories/incident_repository.dart';

/// Use case: the city the map opens on and its reports (HU-13).
///
/// Until the city switcher exists (HU-21), the map shows the citizen's
/// reference city from the profile. A guest (HU-22) has no profile: the map
/// opens on the covered city nearest to the GPS, or on [guestFallbackCity]
/// when the position is unavailable.
class GetCityMapUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final CityRepository _cities;
  final IncidentRepository _incidents;
  final LocationRepository _location;

  GetCityMapUseCase(this._auth, this._profiles, this._cities, this._incidents, this._location);

  /// Where a guest without GPS starts, until HU-21 lets them choose.
  static const String guestFallbackCity = 'Cali';

  Future<(City, List<IncidentMarker>)> call() async {
    final cities = await _cities.getCities();
    if (cities.isEmpty) throw Exception('No hay ciudades disponibles.');

    final user = _auth.currentUser();
    final City city;
    if (user == null) {
      city = await _guestCity(cities);
    } else {
      final profile = await _profiles.getProfile(user.id);
      final match = cities.where((c) => c.name == profile.cityName);
      if (match.isEmpty) throw Exception('No encontramos tu ciudad en el mapa.');
      city = match.last;
    }

    final markers = await _incidents.getCityIncidents(city.name);
    return (city, markers);
  }

  Future<City> _guestCity(List<City> cities) async {
    try {
      final position = await _location.currentCoordinates();
      return DetectNearestCityUseCase.resolve(position, cities);
    } on Exception {
      final fallback = cities.where((c) => c.name == guestFallbackCity);
      return fallback.isEmpty ? cities.first : fallback.first;
    }
  }
}

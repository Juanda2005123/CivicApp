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
/// The map shows the city the citizen picked on the switcher (HU-21), or else
/// their last city from the profile. A guest (HU-22) has no profile: the map
/// opens on the covered city nearest to the GPS, or on [guestFallbackCity]
/// when the position is unavailable.
class GetCityMapUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final CityRepository _cities;
  final IncidentRepository _incidents;
  final LocationRepository _location;

  GetCityMapUseCase(this._auth, this._profiles, this._cities, this._incidents, this._location);

  /// Where a guest without GPS starts, until they choose another city (HU-21).
  static const String guestFallbackCity = 'Cali';

  /// [city] is the city the citizen chose on the switcher; without it the map
  /// opens on their last city, or on the nearest one for a guest.
  Future<(City, List<IncidentMarker>)> call({City? city}) async {
    final target = city ?? await _defaultCity();
    final markers = await _incidents.getCityIncidents(target.name);
    return (target, markers);
  }

  Future<City> _defaultCity() async {
    final cities = await _cities.getCities();
    if (cities.isEmpty) throw Exception('No hay ciudades disponibles.');

    final user = _auth.currentUser();
    if (user == null) return _guestCity(cities);

    final profile = await _profiles.getProfile(user.id);
    for (final name in [profile.lastCityName, profile.cityName]) {
      final match = cities.where((c) => c.name == name);
      if (match.isNotEmpty) return match.last;
    }
    throw Exception('No encontramos tu ciudad en el mapa.');
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

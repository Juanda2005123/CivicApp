import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/city_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';

import '../entities/incident_marker.dart';
import '../repositories/incident_repository.dart';

/// Use case: the city the map opens on and its reports (HU-13).
///
/// Until the city switcher exists (HU-21), the map shows the citizen's
/// reference city from the profile.
class GetCityMapUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final CityRepository _cities;
  final IncidentRepository _incidents;

  GetCityMapUseCase(this._auth, this._profiles, this._cities, this._incidents);

  Future<(City, List<IncidentMarker>)> call() async {
    final user = _auth.currentUser();
    if (user == null) throw Exception('Inicia sesión para ver el mapa.');

    final profile = await _profiles.getProfile(user.id);
    final cities = await _cities.getCities();
    City? city;
    for (final candidate in cities) {
      if (candidate.name == profile.cityName) city = candidate;
    }
    if (city == null) throw Exception('No encontramos tu ciudad en el mapa.');

    final markers = await _incidents.getCityIncidents(city.name);
    return (city, markers);
  }
}

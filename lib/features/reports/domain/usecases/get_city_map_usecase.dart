import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/city_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/detect_nearest_city_usecase.dart';

import '../entities/incident.dart';
import '../entities/incident_marker.dart';
import '../repositories/incident_repository.dart';
import 'geocode_address_usecase.dart';

/// Use case: the city the map opens on and its reports (HU-13).
///
/// The map shows the city the citizen picked on the switcher (HU-21). Without
/// a choice it opens on the covered city where the citizen is, when the GPS
/// answers and the position is inside coverage (HU-13); otherwise on their last
/// city from the profile. A guest (HU-22) has no profile: the map opens on the
/// covered city nearest to the GPS, or on [guestFallbackCity] when the position
/// is unavailable.
///
/// The map shows what is damaged today: resolved reports (HU-25) are left out;
/// the community feed and the report detail still show them.
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
  /// opens on the city where they are, else on their last city, or on the
  /// nearest one for a guest. Opening on the city where they are never changes
  /// the saved last city (HU-21).
  ///
  /// [position] is the GPS position the caller already read, so the permission
  /// is asked once. With [positionRead] true the use case never reads the GPS
  /// itself, even when [position] is null (the caller tried and it failed).
  Future<(City, List<IncidentMarker>)> call({
    City? city,
    Coordinates? position,
    bool positionRead = false,
  }) async {
    final target = city ?? await _defaultCity(position, positionRead);
    final markers = await _incidents.getCityIncidents(target.name);
    return (target, markers.where((m) => m.status != IncidentStatus.resolved).toList());
  }

  Future<City> _defaultCity(Coordinates? position, bool positionRead) async {
    final cities = await _cities.getCities();
    if (cities.isEmpty) throw Exception('No hay ciudades disponibles.');

    final user = _auth.currentUser();
    if (user == null) return _guestCity(cities, position, positionRead);

    final here = position == null ? null : _coverageCityAt(position, cities);
    if (here != null) return here;

    final profile = await _profiles.getProfile(user.id);
    for (final name in [profile.lastCityName, profile.cityName]) {
      final match = cities.where((c) => c.name == name);
      if (match.isNotEmpty) return match.last;
    }
    throw Exception('No encontramos tu ciudad en el mapa.');
  }

  /// Whether [position] is inside [city]'s coverage (RN-12).
  static bool covers(City city, Coordinates position) {
    final center = Coordinates(latitude: city.latitude, longitude: city.longitude);
    return position.distanceInMetersTo(center) <= GeocodeAddressUseCase.maxDistanceFromCityMeters;
  }

  /// The coverage city that contains [position], or null when it is outside
  /// coverage: then the profile decides.
  City? _coverageCityAt(Coordinates position, List<City> cities) {
    final city = DetectNearestCityUseCase.resolve(position, cities);
    return covers(city, position) ? city : null;
  }

  Future<City> _guestCity(List<City> cities, Coordinates? position, bool positionRead) async {
    try {
      final here = position ?? (positionRead ? null : await _location.currentCoordinates());
      if (here == null) throw Exception('Sin posición.');
      return DetectNearestCityUseCase.resolve(here, cities);
    } on Exception {
      final fallback = cities.where((c) => c.name == guestFallbackCity);
      return fallback.isEmpty ? cities.first : fallback.first;
    }
  }
}

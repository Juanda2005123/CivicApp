import '../../../auth/domain/entities/city.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/repositories/profile_repository.dart';
import '../repositories/recent_cities_repository.dart';
import 'get_city_options_usecase.dart';

/// Use case: the citizen picks another city to explore (HU-21).
///
/// A signed-in citizen keeps it as `last_city`, so the next session opens
/// there. A guest has no profile: the city is only remembered on the device.
/// The saved city goes first in the recents, without repeats.
class SwitchCityUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final RecentCitiesRepository _recent;

  SwitchCityUseCase(this._auth, this._profiles, this._recent);

  Future<void> call(City city) async {
    final user = _auth.currentUser();
    if (user != null) await _profiles.updateLastCity(user.id, city.name);

    final names = await _recent.getRecentNames();
    final updated = [city.name, ...names.where((name) => name != city.name)];
    await _recent.saveRecentNames(updated.take(GetCityOptionsUseCase.maxRecent).toList());
  }
}

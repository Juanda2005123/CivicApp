import '../../../auth/domain/entities/city.dart';
import '../../../auth/domain/repositories/city_repository.dart';
import '../entities/city_options.dart';
import '../repositories/recent_cities_repository.dart';

/// Use case: the options of the city switcher before any search (HU-21).
class GetCityOptionsUseCase {
  final CityRepository _cities;
  final RecentCitiesRepository _recent;

  GetCityOptionsUseCase(this._cities, this._recent);

  /// Shortcuts of the quick chips, in display order.
  static const List<String> quickCityNames = [
    'Bogotá',
    'Medellín',
    'Cali',
    'Barranquilla',
    'Bucaramanga',
  ];

  /// Most recent cities shown.
  static const int maxRecent = 3;

  Future<CityOptions> call() async {
    final all = await _cities.getCities();
    final recentNames = await _recent.getRecentNames();

    City? byName(String name) {
      for (final city in all) {
        if (city.name == name) return city;
      }
      return null;
    }

    final recent = [for (final name in recentNames.take(maxRecent)) ?byName(name)];
    final quick = [for (final name in quickCityNames) ?byName(name)];
    return CityOptions(all: all, recent: recent, quick: quick);
  }
}

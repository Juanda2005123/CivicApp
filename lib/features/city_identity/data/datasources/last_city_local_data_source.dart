import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/city_ref.dart';

/// Keeps on the device the last city the app dressed for. It is only a look:
/// nothing is sent anywhere.
class LastCityLocalDataSource {
  static const String _nameKey = 'city_identity.last_city_name';
  static const String _departmentKey = 'city_identity.last_city_department';

  Future<CityRef?> read() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final name = preferences.getString(_nameKey);
      if (name == null) return null;
      return CityRef(name: name, department: preferences.getString(_departmentKey) ?? '');
    } catch (e) {
      throw Exception('No pudimos leer la última ciudad: $e');
    }
  }

  Future<void> save(CityRef city) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_nameKey, city.name);
      await preferences.setString(_departmentKey, city.department);
    } catch (e) {
      throw Exception('No pudimos guardar la ciudad: $e');
    }
  }
}

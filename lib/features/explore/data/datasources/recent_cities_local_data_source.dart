import 'package:shared_preferences/shared_preferences.dart';

/// The only class that reads and writes the recent cities on the device.
class RecentCitiesLocalDataSource {
  static const String _key = 'recent_cities';

  Future<List<String>> getRecentNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  Future<void> saveRecentNames(List<String> names) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, names);
  }
}

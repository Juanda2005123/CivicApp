/// Contract for the cities the citizen explored last (HU-21), newest first.
/// They live on the device, so a guest has them too.
abstract class RecentCitiesRepository {
  Future<List<String>> getRecentNames();

  Future<void> saveRecentNames(List<String> names);
}

import '../entities/incident_category.dart';

/// Abstract contract for damage categorization catalogs.
abstract class CategoryRepository {
  /// Loads all active incident categories.
  Future<List<IncidentCategory>> getCategories();
}

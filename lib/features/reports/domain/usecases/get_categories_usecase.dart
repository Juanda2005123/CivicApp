import '../entities/incident_category.dart';
import '../repositories/category_repository.dart';

/// Fetches active road incident categories.
class GetCategoriesUseCase {
  final CategoryRepository _categoryRepository;

  GetCategoriesUseCase(this._categoryRepository);

  Future<List<IncidentCategory>> call() {
    return _categoryRepository.getCategories();
  }
}

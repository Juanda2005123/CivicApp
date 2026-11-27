import '../entities/civic_impact.dart';
import '../repositories/impact_repository.dart';

/// Reads the impact counters of a citizen (HU-23, criterion 2).
class GetCivicImpactUseCase {
  final ImpactRepository _repository;

  GetCivicImpactUseCase(this._repository);

  Future<CivicImpact> call(String userId) => _repository.getImpact(userId);
}

import '../../../reports/domain/entities/feed_incident.dart';
import '../repositories/impact_repository.dart';

/// The reports a citizen published, newest first, for "Mis reportes" (HU-23, criterion 5).
class GetMyReportsUseCase {
  final ImpactRepository _repository;

  GetMyReportsUseCase(this._repository);

  Future<List<FeedIncident>> call(String userId) => _repository.getMyReports(userId);
}

import '../entities/feed_incident.dart';
import '../repositories/incident_repository.dart';

/// Use case: one page of the community feed of a city (HU-19).
///
/// The page size and the "is there more?" rule live here, not in the Bloc nor
/// in the data source: a full page means there may be another one, a shorter
/// page is the last.
class GetCityFeedUseCase {
  final IncidentRepository _incidents;

  GetCityFeedUseCase(this._incidents);

  /// Reports per page (HU-19, criterion 2).
  static const int pageSize = 20;

  /// The reports that start after [offset] ones, newest first, and whether
  /// another page may follow. A city with exactly [pageSize] reports answers
  /// `hasMore` once more and the next call comes back empty.
  Future<(List<FeedIncident>, bool)> call(String city, {int offset = 0}) async {
    if (city.trim().isEmpty) throw Exception('Elige una ciudad para ver sus reportes.');
    if (offset < 0) throw Exception('La página de reportes no es válida.');

    final items = await _incidents.getCityFeed(city, offset: offset, limit: pageSize);
    return (items, items.length >= pageSize);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../reports/data/models/feed_incident_model.dart';
import '../../../reports/domain/entities/feed_incident.dart';
import '../../domain/entities/civic_impact.dart';
import '../../domain/entities/rank_level.dart';
import '../models/rank_level_model.dart';

/// Reads what the civic impact dashboard shows (HU-23): the counters as exact
/// counts computed by the database, the civic ladder and the citizen's own reports.
class ImpactRemoteDataSource {
  final SupabaseClient _client;

  ImpactRemoteDataSource(this._client);

  /// The four counters of [userId]. They are counted on the server so they
  /// always match the real activity, even when a report was deleted.
  Future<CivicImpact> getImpact(String userId) async {
    try {
      final reports = _client.from('road_incident').count(CountOption.exact).eq('id_reporter_user', userId);
      // Endorsements on the citizen's reports: an inner join keeps only the votes
      // whose report was written by the citizen.
      final received = _client
          .from('incident_upvote')
          .select('id_user, road_incident!inner(id_reporter_user)')
          .eq('road_incident.id_reporter_user', userId)
          .count(CountOption.exact);
      final given = _client.from('incident_upvote').count(CountOption.exact).eq('id_user', userId);
      final comments = _client.from('incident_comment').count(CountOption.exact).eq('id_user', userId);

      // Future.wait rethrows the first real exception (a record's wait would wrap it).
      await Future.wait<void>([reports, received, given, comments]);

      return CivicImpact(
        reportsCreated: await reports,
        endorsementsReceived: (await received).count,
        endorsementsGiven: await given,
        commentsPublished: await comments,
      );
    } on PostgrestException catch (e) {
      throw Exception('No pudimos cargar tu impacto: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('No pudimos cargar tu impacto.');
    }
  }

  Future<List<RankLevel>> getRanks() async {
    try {
      final rows = await _client.from('civic_rank').select(RankLevelModel.select).order('min_xp');
      return (rows as List<dynamic>)
          .map((row) => RankLevelModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('No pudimos cargar los niveles cívicos: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('No pudimos cargar los niveles cívicos.');
    }
  }

  /// Reports of [userId], newest first. The id is a second sort key so the
  /// order is stable when two reports share an instant.
  Future<List<FeedIncident>> getMyReports(String userId) async {
    try {
      final rows = await _client
          .from('road_incident')
          .select(FeedIncidentModel.select)
          .eq('id_reporter_user', userId)
          .order('created_at', ascending: false)
          .order('id_incident', ascending: false);
      return (rows as List<dynamic>)
          .map((row) => FeedIncidentModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('No pudimos cargar tus reportes: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('No pudimos cargar tus reportes.');
    }
  }
}

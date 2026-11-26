import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/picked_photo.dart';
import '../models/incident_resolution_model.dart';
import 'photo_storage_data_source.dart';

/// Reads and writes `incident_resolution`, `resolution_confirmation` and
/// `resolution_objection` through PostgREST, and stores the repair photo in the
/// evidence bucket. The rules (quorum, XP, status of the report) are triggers
/// of migration 010.
class ResolutionRemoteDataSource {
  static const String _columns =
      '*, proponent:user_profile!fk_resolution_proponent_user(full_name, show_real_name), '
      'resolution_confirmation(id_user), resolution_objection(id_user)';

  /// Postgres code of a unique violation: a second pending proposal hit
  /// `idx_single_active_resolution` at the same moment as another one.
  static const String _uniqueViolation = '23505';

  final SupabaseClient _client;
  final PhotoStorageDataSource _storage;

  ResolutionRemoteDataSource(this._client, this._storage);

  /// The newest pending proposal of a report, or null.
  Future<IncidentResolutionModel?> getActiveResolution(String incidentId) async {
    try {
      final row = await _client
          .from('incident_resolution')
          .select(_columns)
          .eq('id_incident', incidentId)
          .eq('status', 'PENDING')
          .order('proposed_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row == null ? null : IncidentResolutionModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw Exception('No pudimos cargar la propuesta de reparación: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al cargar la propuesta de reparación.');
    }
  }

  /// Uploads the photo and creates the proposal. The row is read back after
  /// the insert so an author's proposal arrives already approved.
  Future<IncidentResolutionModel> proposeResolution({
    required String incidentId,
    required String userId,
    required PickedPhoto photo,
    required String description,
  }) async {
    try {
      final photoUrl = await _storage.uploadPhoto(
        bytes: photo.bytes,
        extension: photo.extension,
        reporterId: userId,
      );

      final inserted = await _client
          .from('incident_resolution')
          .insert({
            'id_incident': incidentId,
            'id_proponent_user': userId,
            'photo_evidence_url': photoUrl,
            'description': description,
          })
          .select('id_resolution')
          .single();

      final row = await _client
          .from('incident_resolution')
          .select(_columns)
          .eq('id_resolution', inserted['id_resolution'] as Object)
          .single();
      return IncidentResolutionModel.fromJson(row);
    } on PostgrestException catch (e) {
      if (e.code == _uniqueViolation) {
        throw Exception('Ya hay una propuesta de reparación en verificación para este reporte.');
      }
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al enviar la propuesta de reparación.');
    }
  }

  Future<void> confirmResolution({required String resolutionId, required String userId}) =>
      _vote('resolution_confirmation', resolutionId: resolutionId, userId: userId);

  Future<void> objectResolution({required String resolutionId, required String userId}) =>
      _vote('resolution_objection', resolutionId: resolutionId, userId: userId);

  Future<void> acceptResolution(String resolutionId) =>
      _decide(resolutionId, {'status': 'APPROVED_BY_AUTHOR'});

  Future<void> rejectResolution({required String resolutionId, required String reason}) =>
      _decide(resolutionId, {'status': 'REJECTED_BY_AUTHOR', 'rejection_reason': reason});

  Future<void> _vote(String table, {required String resolutionId, required String userId}) async {
    try {
      await _client.from(table).insert({'id_resolution': resolutionId, 'id_user': userId});
    } on PostgrestException catch (e) {
      if (e.code == _uniqueViolation) {
        throw Exception('Ya votaste esta propuesta.');
      }
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al registrar tu voto.');
    }
  }

  /// The update policy only shows the row to the report author; anyone else
  /// changes nothing, so an empty answer is reported as an error.
  Future<void> _decide(String resolutionId, Map<String, dynamic> values) async {
    try {
      final rows = await _client
          .from('incident_resolution')
          .update(values)
          .eq('id_resolution', resolutionId)
          .select('id_resolution');
      if ((rows as List<dynamic>).isEmpty) {
        throw Exception('Solo quien publicó el reporte puede aceptar o rechazar la propuesta.');
      }
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al guardar tu decisión.');
    }
  }
}

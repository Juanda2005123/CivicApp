import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/picked_photo.dart';
import '../models/incident_comment_model.dart';
import 'photo_storage_data_source.dart';

/// Reads and writes `incident_comment` and `comment_photo` through PostgREST, and
/// stores the comment photo in the evidence bucket.
class CommentRemoteDataSource {
  static const String _columns =
      '*, author:user_profile!fk_comment_user(full_name, show_real_name, id_rank, civic_rank(name)), comment_photo(file_url)';

  final SupabaseClient _client;
  final PhotoStorageDataSource _storage;

  CommentRemoteDataSource(this._client, this._storage);

  /// Comments of a report, oldest first (HU-17, criterion 1).
  Future<List<IncidentCommentModel>> getComments(String incidentId) async {
    try {
      final rows = await _client
          .from('incident_comment')
          .select(_columns)
          .eq('id_incident', incidentId)
          .order('created_at', ascending: true);

      return (rows as List<dynamic>)
          .map((row) => IncidentCommentModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('No pudimos cargar los comentarios: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al cargar los comentarios.');
    }
  }

  /// Uploads the photo, publishes the comment and links the photo. If linking
  /// the photo fails the comment is deleted again, so no half comment is left
  /// (and the XP the server gave goes back with it).
  Future<IncidentCommentModel> addComment({
    required String incidentId,
    required String userId,
    required String text,
    PickedPhoto? photo,
  }) async {
    try {
      final photoUrl = photo == null
          ? null
          : await _storage.uploadPhoto(
              bytes: photo.bytes,
              extension: photo.extension,
              reporterId: userId,
            );

      final row = await _client
          .from('incident_comment')
          .insert({'id_incident': incidentId, 'id_user': userId, 'content': text})
          .select(_columns)
          .single();
      final json = Map<String, dynamic>.from(row);

      if (photoUrl != null) {
        try {
          await _client.from('comment_photo').insert({
            'id_comment': json['id_comment'],
            'file_url': photoUrl,
          });
        } catch (_) {
          await _client.from('incident_comment').delete().eq('id_comment', json['id_comment'] as Object);
          throw Exception('No pudimos adjuntar la foto. Inténtalo de nuevo.');
        }
        json['comment_photo'] = {'file_url': photoUrl};
      }

      return IncidentCommentModel.fromJson(json);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al publicar el comentario.');
    }
  }

  /// Deletes the comment; its photo row goes with it (cascade).
  Future<void> deleteComment(String commentId) async {
    try {
      await _client.from('incident_comment').delete().eq('id_comment', commentId);
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al eliminar el comentario.');
    }
  }
}

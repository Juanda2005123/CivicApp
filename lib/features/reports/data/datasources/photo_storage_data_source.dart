import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads photographic evidence to the Supabase Storage bucket.
class PhotoStorageDataSource {
  static const String bucketName = 'incident-evidence';
  final SupabaseClient _client;

  PhotoStorageDataSource(this._client);

  /// Uploads raw image [bytes] to the storage bucket and returns its public URL.
  Future<String> uploadPhoto({
    required Uint8List bytes,
    required String extension,
    required String reporterId,
  }) async {
    try {
      final cleanExt = extension.toLowerCase().replaceAll('.', '');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = Random().nextInt(999999).toString().padLeft(6, '0');
      final path = '$reporterId/$timestamp-$randomSuffix.$cleanExt';

      await _client.storage.from(bucketName).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: _resolveContentType(cleanExt),
              upsert: false,
            ),
          );

      return _client.storage.from(bucketName).getPublicUrl(path);
    } on StorageException catch (e) {
      throw Exception('No pudimos subir la foto de evidencia: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al procesar la subida de fotografía.');
    }
  }

  String _resolveContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}

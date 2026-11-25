import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

/// The only class that reads and writes the `user_profile` table.
class ProfileRemoteDataSource {
  final SupabaseClient _client;

  ProfileRemoteDataSource(this._client);

  Future<void> createProfile(ProfileModel profile) async {
    try {
      await _client.from('user_profile').insert(profile.toInsertJson());
    } on PostgrestException catch (e) {
      throw Exception('No pudimos guardar tu perfil: ${e.message}');
    }
  }

  Future<ProfileModel> getProfile(String id) async {
    try {
      final row = await _client
          .from('user_profile')
          .select('*, civic_rank(name)')
          .eq('id_user', id)
          .maybeSingle();
      if (row == null) throw Exception('No encontramos tu perfil.');
      return ProfileModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw Exception('No pudimos cargar tu perfil: ${e.message}');
    }
  }

  Future<void> updateLastCity(String id, String cityName) async {
    try {
      await _client.from('user_profile').update({'last_city': cityName}).eq('id_user', id);
    } on PostgrestException catch (e) {
      throw Exception('No pudimos guardar tu ciudad: ${e.message}');
    }
  }

  Future<String> updateAvatar({
    required String id,
    required Uint8List bytes,
    required String extension,
  }) async {
    const bucketName = 'incident-evidence';
    try {
      final cleanExt = extension.toLowerCase().replaceAll('.', '');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomSuffix = Random().nextInt(999999).toString().padLeft(6, '0');
      final path = 'avatars/$id/$timestamp-$randomSuffix.$cleanExt';

      await _client.storage.from(bucketName).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: _contentType(cleanExt),
              upsert: false,
            ),
          );

      final publicUrl = _client.storage.from(bucketName).getPublicUrl(path);
      await _client.from('user_profile').update({'profile_picture_url': publicUrl}).eq('id_user', id);
      return publicUrl;
    } on StorageException catch (e) {
      throw Exception('No pudimos subir tu avatar: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('No pudimos guardar tu avatar: ${e.message}');
    }
  }

  String _contentType(String ext) {
    switch (ext) {
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

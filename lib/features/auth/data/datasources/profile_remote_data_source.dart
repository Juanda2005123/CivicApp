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
}

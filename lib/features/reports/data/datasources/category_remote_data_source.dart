import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident_category_model.dart';

/// Reads the `incident_category` master catalog from Supabase PostgREST.
class CategoryRemoteDataSource {
  final SupabaseClient _client;

  CategoryRemoteDataSource(this._client);

  Future<List<IncidentCategoryModel>> getCategories() async {
    try {
      final response = await _client
          .from('incident_category')
          .select()
          .order('id_category', ascending: true);

      return (response as List<dynamic>)
          .map((row) => IncidentCategoryModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('No pudimos cargar las categorías: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al conectar con el catálogo de categorías.');
    }
  }
}

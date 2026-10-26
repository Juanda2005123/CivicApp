import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/city.dart';

/// Reads the official coverage cities from the `coverage_city` table.
class CityRemoteDataSource {
  final SupabaseClient _client;

  CityRemoteDataSource(this._client);

  Future<List<City>> getCities() async {
    try {
      final rows = await _client.from('coverage_city').select().order('name');
      return rows.map(_toCity).toList();
    } on PostgrestException catch (e) {
      throw Exception('Could not load the coverage cities: ${e.message}');
    }
  }

  City _toCity(Map<String, dynamic> row) {
    return City(
      id: row['id_city'] as int,
      name: row['name'] as String,
      department: row['department'] as String,
      latitude: (row['center_latitude'] as num).toDouble(),
      longitude: (row['center_longitude'] as num).toDouble(),
      isCapital: row['is_capital'] as bool,
    );
  }
}

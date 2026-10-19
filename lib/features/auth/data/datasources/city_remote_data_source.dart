import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/dane_cities.dart';

/// City remote data source:
/// Queries `coverage_city` from Supabase with offline fallback to canonical `dane_cities.dart`.
class CityRemoteDataSource {
  final SupabaseClient? supabaseClient;

  CityRemoteDataSource({this.supabaseClient});

  Future<List<DaneCity>> getCities() async {
    if (supabaseClient != null) {
      // 1. Primary: Query new English table `coverage_city`
      try {
        final List<dynamic> data = await supabaseClient!
            .from('coverage_city')
            .select()
            .order('name');

        if (data.isNotEmpty) {
          return data.map((json) {
            return DaneCity(
              id: (json['id_city'] ?? json['id'] as num).toInt(),
              nombre: (json['name'] ?? json['nombre']) as String,
              departamento: (json['department'] ?? json['departamento']) as String,
              latitud: (json['center_latitude'] ?? json['latitud_centro'] as num).toDouble(),
              longitud: (json['center_longitude'] ?? json['longitud_centro'] as num).toDouble(),
              esCapital: (json['is_capital'] ?? json['es_capital'] as bool?) ?? false,
            );
          }).toList();
        }
      } catch (_) {}

      // 2. Fallback: Query legacy Spanish table `ciudad_cobertura`
      try {
        final List<dynamic> legacyData = await supabaseClient!
            .from('ciudad_cobertura')
            .select()
            .order('nombre');

        if (legacyData.isNotEmpty) {
          return legacyData.map((json) {
            return DaneCity(
              id: (json['id'] as num).toInt(),
              nombre: json['nombre'] as String,
              departamento: json['departamento'] as String,
              latitud: (json['latitud_centro'] as num).toDouble(),
              longitud: (json['longitud_centro'] as num).toDouble(),
              esCapital: json['es_capital'] as bool? ?? false,
            );
          }).toList();
        }
      } catch (_) {}
    }

    // 3. Guaranteed Canonical Offline Fallback
    return DaneCitiesCatalog.cities;
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/dane_cities.dart';

/// Fuente de datos de ciudades con patrón Opción B:
/// Prioriza consulta en vivo a PostgreSQL/Supabase con fallback offline a `dane_cities.dart`.
class CityRemoteDataSource {
  final SupabaseClient? supabaseClient;

  CityRemoteDataSource({this.supabaseClient});

  Future<List<DaneCity>> getCities() async {
    if (supabaseClient != null) {
      try {
        final List<dynamic> data = await supabaseClient!
            .from('ciudad_cobertura')
            .select()
            .order('nombre');

        if (data.isNotEmpty) {
          return data.map((json) {
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
      } catch (_) {
        // En caso de error de red o timeout, aplica el fallback offline acordado
      }
    }

    // Fallback a catálogo canónico offline
    return DaneCitiesCatalog.cities;
  }
}

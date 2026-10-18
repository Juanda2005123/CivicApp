import '../../domain/entities/usuario.dart';

/// Modelo de datos (DTO) que mapea la representación en PostgreSQL / Supabase
/// hacia la Entidad de Dominio `Usuario`.
class UsuarioModel extends Usuario {
  const UsuarioModel({
    required super.id,
    required super.email,
    required super.nombreCompleto,
    required super.ciudadResidenciaId,
    super.ciudadNombre,
    required super.nivelReputacionId,
    super.nivelReputacionNombre = 'Observador',
    required super.puntosReputacion,
    super.activo = true,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    // Si viene anidada la ciudad o el nivel de reputación desde Supabase
    final ciudadData = json['ciudad_cobertura'] as Map<String, dynamic>?;
    final String? ciudadDisplay = ciudadData != null
        ? "${ciudadData['nombre']} (${ciudadData['departamento']})"
        : null;

    final nivelData = json['nivel_reputacion'] as Map<String, dynamic>?;
    final String nivelNombre = nivelData?['nombre'] ?? 'Observador';

    return UsuarioModel(
      id: json['id'] as String,
      email: json['email'] as String,
      nombreCompleto: json['nombre_completo'] as String? ?? 'Ciudadano VIGÍA',
      ciudadResidenciaId: (json['ciudad_residencia_id'] as num?)?.toInt() ?? 1,
      ciudadNombre: ciudadDisplay,
      nivelReputacionId: (json['nivel_reputacion_id'] as num?)?.toInt() ?? 1,
      nivelReputacionNombre: nivelNombre,
      puntosReputacion: (json['puntos_reputacion'] as num?)?.toInt() ?? 0,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre_completo': nombreCompleto,
      'ciudad_residencia_id': ciudadResidenciaId,
      'nivel_reputacion_id': nivelReputacionId,
      'puntos_reputacion': puntosReputacion,
      'activo': activo,
    };
  }

  Usuario toEntity() {
    return Usuario(
      id: id,
      email: email,
      nombreCompleto: nombreCompleto,
      ciudadResidenciaId: ciudadResidenciaId,
      ciudadNombre: ciudadNombre,
      nivelReputacionId: nivelReputacionId,
      nivelReputacionNombre: nivelReputacionNombre,
      puntosReputacion: puntosReputacion,
      activo: activo,
    );
  }
}

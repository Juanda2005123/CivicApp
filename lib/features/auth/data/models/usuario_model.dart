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
    // Soporte para rango_civico (schema.sql) o nivel_reputacion
    final rangoData = (json['rango_civico'] ?? json['nivel_reputacion']) as Map<String, dynamic>?;
    final String rangoNombre = rangoData?['nombre'] ?? 'Observador';

    // Soporte para ciudad_referencia (schema.sql) o ciudad_cobertura
    final ciudadData = json['ciudad_cobertura'] as Map<String, dynamic>?;
    final String ciudadDisplay = ciudadData != null
        ? "${ciudadData['nombre']} (${ciudadData['departamento']})"
        : (json['ciudad_referencia'] ?? json['ultima_ciudad'] ?? 'Cali');

    final String userId = (json['id_usuario'] ?? json['id'] ?? '').toString();
    final String userEmail = (json['correo_electronico'] ?? json['email'] ?? '').toString();
    final String userNombre = (json['nombre_completo'] ?? 'Ciudadano VIGÍA').toString();
    final int userRangoId = (json['id_rango'] ?? json['nivel_reputacion_id'] as num?)?.toInt() ?? 1;
    final int userPuntos = (json['puntos_experiencia'] ?? json['puntos_reputacion'] as num?)?.toInt() ?? 0;
    final bool userActivo = json['activo'] as bool? ?? true;

    return UsuarioModel(
      id: userId,
      email: userEmail,
      nombreCompleto: userNombre,
      ciudadResidenciaId: (json['ciudad_residencia_id'] as num?)?.toInt() ?? 1,
      ciudadNombre: ciudadDisplay,
      nivelReputacionId: userRangoId,
      nivelReputacionNombre: rangoNombre,
      puntosReputacion: userPuntos,
      activo: userActivo,
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

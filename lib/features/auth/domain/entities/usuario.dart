import 'package:equatable/equatable.dart';

/// Entidad pura de dominio que representa a un ciudadano registrado en VIGÍA.
/// No tiene dependencias de infraestructura ni de frameworks de base de datos.
class Usuario extends Equatable {
  final String id;
  final String email;
  final String nombreCompleto;
  final int ciudadResidenciaId;
  final String? ciudadNombre;
  final int nivelReputacionId;
  final String nivelReputacionNombre;
  final int puntosReputacion;
  final bool activo;

  const Usuario({
    required this.id,
    required this.email,
    required this.nombreCompleto,
    required this.ciudadResidenciaId,
    this.ciudadNombre,
    required this.nivelReputacionId,
    this.nivelReputacionNombre = 'Observador',
    required this.puntosReputacion,
    this.activo = true,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        nombreCompleto,
        ciudadResidenciaId,
        ciudadNombre,
        nivelReputacionId,
        nivelReputacionNombre,
        puntosReputacion,
        activo,
      ];
}

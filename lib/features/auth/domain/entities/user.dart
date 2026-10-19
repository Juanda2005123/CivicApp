import 'package:equatable/equatable.dart';

/// Pure domain entity representing a registered citizen in VIGÍA.
/// Completely decoupled from database schemas and infrastructure frameworks.
class User extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final int residenceCityId;
  final String? cityName;
  final int rankId;
  final String rankName;
  final int reputationPoints;
  final bool isActive;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.residenceCityId,
    this.cityName,
    required this.rankId,
    this.rankName = 'Urban Observer',
    required this.reputationPoints,
    this.isActive = true,
  });

  // Backward-compatibility accessors during progressive migration
  String get nombreCompleto => fullName;
  int get ciudadResidenciaId => residenceCityId;
  String? get ciudadNombre => cityName;
  int get nivelReputacionId => rankId;
  String get nivelReputacionNombre => rankName;
  int get puntosReputacion => reputationPoints;
  bool get activo => isActive;

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        residenceCityId,
        cityName,
        rankId,
        rankName,
        reputationPoints,
        isActive,
      ];
}

/// Backward compatibility typedef for progressive migration
typedef Usuario = User;

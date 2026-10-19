import '../../domain/entities/user.dart';

/// Data Transfer Object (DTO) mapping Supabase / PostgreSQL tables
/// to the pure Domain Entity `User`.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.residenceCityId,
    super.cityName,
    required super.rankId,
    super.rankName = 'Urban Observer',
    required super.reputationPoints,
    super.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Support civic_rank (English schema) or rango_civico (legacy)
    final rankData = (json['civic_rank'] ?? json['rango_civico'] ?? json['nivel_reputacion']) as Map<String, dynamic>?;
    final String rankTitle = rankData?['name'] ?? rankData?['nombre'] ?? 'Urban Observer';

    // Support coverage_city (English schema) or ciudad_cobertura (legacy)
    final cityData = (json['coverage_city'] ?? json['ciudad_cobertura']) as Map<String, dynamic>?;
    final String cityDisplay = cityData != null
        ? "${cityData['name'] ?? cityData['nombre']} (${cityData['department'] ?? cityData['departamento']})"
        : (json['reference_city'] ?? json['last_city'] ?? json['ciudad_referencia'] ?? json['ultima_ciudad'] ?? 'Cali');

    final String userId = (json['id_user'] ?? json['id_usuario'] ?? json['id'] ?? '').toString();
    final String userEmail = (json['email'] ?? json['correo_electronico'] ?? '').toString();
    final String userName = (json['full_name'] ?? json['nombre_completo'] ?? 'Citizen VIGÍA').toString();
    final int userRankId = (json['id_rank'] ?? json['id_rango'] ?? json['nivel_reputacion_id'] as num?)?.toInt() ?? 1;
    final int userPoints = (json['experience_points'] ?? json['puntos_experiencia'] ?? json['puntos_reputacion'] as num?)?.toInt() ?? 0;
    final bool userIsActive = (json['is_active'] ?? json['activo'] as bool?) ?? true;

    return UserModel(
      id: userId,
      email: userEmail,
      fullName: userName,
      residenceCityId: (json['residence_city_id'] ?? json['ciudad_residencia_id'] as num?)?.toInt() ?? 1,
      cityName: cityDisplay,
      rankId: userRankId,
      rankName: rankTitle,
      reputationPoints: userPoints,
      isActive: userIsActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': id,
      'email': email,
      'full_name': fullName,
      'residence_city_id': residenceCityId,
      'id_rank': rankId,
      'experience_points': reputationPoints,
      'is_active': isActive,
    };
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      fullName: fullName,
      residenceCityId: residenceCityId,
      cityName: cityName,
      rankId: rankId,
      rankName: rankName,
      reputationPoints: reputationPoints,
      isActive: isActive,
    );
  }
}

/// Backward compatibility typedef
typedef UsuarioModel = UserModel;

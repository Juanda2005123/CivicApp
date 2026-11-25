import 'package:equatable/equatable.dart';

/// Citizen profile stored by VIGÍA, keyed by the Auth user id.
class Profile extends Equatable {
  final String id;
  final String email;
  final String fullName;
  /// City chosen at registration (`reference_city`).
  final String cityName;

  /// City the citizen was exploring last (`last_city`, HU-21): where the map
  /// opens. Defaults to [cityName] for a profile that never switched.
  final String lastCityName;
  final int rankId;
  final String rankName;
  final int experiencePoints;
  final bool showRealName;
  final String? avatarUrl;
  final bool isActive;

  const Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.cityName,
    String? lastCityName,
    this.rankId = 1,
    this.rankName = 'Observador Urbano',
    this.experiencePoints = 0,
    this.showRealName = true,
    this.avatarUrl,
    this.isActive = true,
  }) : lastCityName = lastCityName ?? cityName;

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        cityName,
        lastCityName,
        rankId,
        rankName,
        experiencePoints,
        showRealName,
        avatarUrl,
        isActive,
      ];
}

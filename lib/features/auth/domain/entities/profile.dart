import 'package:equatable/equatable.dart';

/// Citizen profile stored by VIGÍA, keyed by the Auth user id.
class Profile extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String cityName;
  final int rankId;
  final String rankName;
  final int experiencePoints;
  final bool isActive;

  const Profile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.cityName,
    this.rankId = 1,
    this.rankName = 'Urban Observer',
    this.experiencePoints = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        cityName,
        rankId,
        rankName,
        experiencePoints,
        isActive,
      ];
}

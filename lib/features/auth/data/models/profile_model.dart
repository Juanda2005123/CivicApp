import '../../domain/entities/profile.dart';

/// Maps a row of `user_profile` (joined with `civic_rank`) to the [Profile] entity.
///
/// Column names live here and in [ProfileRemoteDataSource]; nothing above the
/// data layer knows them.
class ProfileModel extends Profile {
  const ProfileModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.cityName,
    super.rankId,
    super.rankName,
    super.experiencePoints,
    super.isActive,
  });

  factory ProfileModel.fromEntity(Profile profile) {
    return ProfileModel(
      id: profile.id,
      email: profile.email,
      fullName: profile.fullName,
      cityName: profile.cityName,
      rankId: profile.rankId,
      rankName: profile.rankName,
      experiencePoints: profile.experiencePoints,
      isActive: profile.isActive,
    );
  }

  /// Row selected with `select('*, civic_rank(name)')`.
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final rank = json['civic_rank'] as Map<String, dynamic>?;
    return ProfileModel(
      id: json['id_user'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      cityName: (json['reference_city'] ?? json['last_city']) as String,
      rankId: json['id_rank'] as int,
      rankName: (rank?['name'] as String?) ?? 'Urban Observer',
      experiencePoints: json['experience_points'] as int,
      isActive: json['is_active'] as bool,
    );
  }

  /// Row to insert: every `NOT NULL` column of `user_profile` is set here.
  Map<String, dynamic> toInsertJson() {
    return {
      'id_user': id,
      'id_rank': rankId,
      'full_name': fullName,
      'email': email,
      'reference_city': cityName,
      'last_city': cityName,
      'experience_points': experiencePoints,
      'is_active': isActive,
    };
  }
}

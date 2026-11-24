import '../../domain/entities/rank_level.dart';

/// Maps a row of `civic_rank` to [RankLevel]. Column names live here.
class RankLevelModel extends RankLevel {
  const RankLevelModel({required super.id, required super.name, required super.minXp});

  static const String select = 'id_rank, name, min_xp';

  factory RankLevelModel.fromJson(Map<String, dynamic> json) {
    return RankLevelModel(
      id: json['id_rank'] as int,
      name: json['name'] as String,
      minXp: json['min_xp'] as int,
    );
  }
}

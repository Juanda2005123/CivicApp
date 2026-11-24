import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/dashboard/data/models/rank_level_model.dart';

void main() {
  group('RankLevelModel', () {
    test('reads a civic_rank row', () {
      final rank = RankLevelModel.fromJson({'id_rank': 3, 'name': 'Guardián Cívico', 'min_xp': 2500});

      expect(rank.id, 3);
      expect(rank.name, 'Guardián Cívico');
      expect(rank.minXp, 2500);
    });

    test('selects only the columns it maps', () {
      expect(RankLevelModel.select, 'id_rank, name, min_xp');
    });
  });
}

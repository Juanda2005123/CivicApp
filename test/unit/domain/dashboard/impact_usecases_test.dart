import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/dashboard/domain/entities/civic_impact.dart';
import 'package:vigia_app/features/dashboard/domain/usecases/get_civic_impact_usecase.dart';
import 'package:vigia_app/features/dashboard/domain/usecases/get_my_reports_usecase.dart';
import 'package:vigia_app/features/dashboard/domain/usecases/get_rank_progress_usecase.dart';

import '../../../support/fake_impact_repository.dart';

void main() {
  late FakeImpactRepository repository;

  setUp(() => repository = FakeImpactRepository());

  group('GetCivicImpactUseCase (HU-23, criterion 2)', () {
    test('returns the four counters of the citizen', () async {
      repository.impact = const CivicImpact(
        reportsCreated: 3,
        endorsementsReceived: 12,
        endorsementsGiven: 7,
        commentsPublished: 5,
      );

      final impact = await GetCivicImpactUseCase(repository)('u-1');

      expect(impact.reportsCreated, 3);
      expect(impact.endorsementsReceived, 12);
      expect(impact.endorsementsGiven, 7);
      expect(impact.commentsPublished, 5);
      expect(repository.calls, ['impact.get:u-1']);
    });
  });

  group('GetMyReportsUseCase (HU-23, criterion 5)', () {
    test('asks for the reports of the citizen', () async {
      final reports = await GetMyReportsUseCase(repository)('u-1');

      expect(reports, isEmpty);
      expect(repository.calls, ['impact.reports:u-1']);
    });
  });

  group('GetRankProgressUseCase (RN-09, HU-23 criteria 3 and 4)', () {
    test('0 XP is the first rank with an empty bar toward the second', () async {
      final progress = await GetRankProgressUseCase(repository)(0);

      expect(progress.current.id, 1);
      expect(progress.next?.id, 2);
      expect(progress.fraction, 0);
      expect(progress.xpMissing, 1000);
      expect(progress.isMaxRank, isFalse);
    });

    test('halfway between two thresholds fills half of the bar', () async {
      // 1000 -> 2500 is a span of 1500; 1750 XP is the middle.
      final progress = await GetRankProgressUseCase(repository)(1750);

      expect(progress.current.id, 2);
      expect(progress.next?.id, 3);
      expect(progress.fraction, closeTo(0.5, 0.0001));
      expect(progress.xpMissing, 750);
    });

    test('crossing a threshold exactly promotes the citizen', () async {
      expect((await GetRankProgressUseCase(repository)(999)).current.id, 1);
      expect((await GetRankProgressUseCase(repository)(1000)).current.id, 2);
      expect((await GetRankProgressUseCase(repository)(2500)).current.id, 3);
      expect((await GetRankProgressUseCase(repository)(4000)).current.id, 4);
    });

    test('the highest rank has a full bar and nothing missing', () async {
      final progress = await GetRankProgressUseCase(repository)(5200);

      expect(progress.current.id, 4);
      expect(progress.next, isNull);
      expect(progress.isMaxRank, isTrue);
      expect(progress.fraction, 1);
      expect(progress.xpMissing, 0);
    });

    test('does not depend on the order the database returns the ranks', () async {
      repository.ranks = defaultRanks.reversed.toList();

      final progress = await GetRankProgressUseCase(repository)(1200);

      expect(progress.current.id, 2);
      expect(progress.next?.id, 3);
    });

    test('an empty ladder is an error the citizen can read', () async {
      repository.ranks = const [];

      expect(
        () => GetRankProgressUseCase(repository)(10),
        throwsA(predicate((e) => e.toString().contains('niveles cívicos'))),
      );
    });
  });
}

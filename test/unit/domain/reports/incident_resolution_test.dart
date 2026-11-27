import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_resolution.dart';

import '../../../support/resolution_samples.dart';

void main() {
  group('ResolutionStatus', () {
    test('round-trips every database value', () {
      for (final status in ResolutionStatus.values) {
        expect(ResolutionStatus.fromDbValue(status.toDbValue()), status);
      }
    });

    test('only the two approvals count as approved', () {
      expect(ResolutionStatus.values.where((s) => s.isApproved),
          [ResolutionStatus.approvedByAuthor, ResolutionStatus.approvedByCommunity]);
    });
  });

  group('IncidentResolution (RN-11)', () {
    final proposedAt = DateTime(2026, 11, 20, 9);

    test('a pending proposal is open for 7 days and then expires', () {
      final resolution = sampleResolution(proposedAt: proposedAt);

      expect(resolution.expiresAt, proposedAt.add(const Duration(days: 7)));
      expect(resolution.isOpenAt(proposedAt.add(const Duration(days: 6, hours: 23))), isTrue);
      expect(resolution.isOpenAt(proposedAt.add(const Duration(days: 7))), isFalse);
    });

    test('a decided proposal is never open', () {
      final resolution = sampleResolution(status: ResolutionStatus.rejectedByCommunity, proposedAt: proposedAt);

      expect(resolution.isOpenAt(proposedAt), isFalse);
    });

    test('counts and remembers votes', () {
      final resolution = sampleResolution()
          .withConfirmationBy('v1')
          .withConfirmationBy('v2')
          .withObjectionBy('v3');

      expect(resolution.confirmations, 2);
      expect(resolution.objections, 1);
      expect(resolution.hasConfirmed('v1'), isTrue);
      expect(resolution.hasObjected('v3'), isTrue);
      expect(resolution.hasVoted('v2'), isTrue);
      expect(resolution.hasVoted('v4'), isFalse);
    });
  });
}

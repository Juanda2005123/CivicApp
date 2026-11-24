import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';

import '../../../support/incident_samples.dart';

void main() {
  group('Incident endorsements (HU-15, HU-16)', () {
    test('isEndorsedBy tells whether the citizen is among the endorsers', () {
      final incident = sampleIncident(upvoterIds: ['voter-1'], upvotesCount: 1);

      expect(incident.isEndorsedBy('voter-1'), isTrue);
      expect(incident.isEndorsedBy('voter-2'), isFalse);
    });

    test('withEndorsementBy adds one endorsement and is idempotent', () {
      final incident = sampleIncident(upvotesCount: 2);

      final once = incident.withEndorsementBy('me');
      final twice = once.withEndorsementBy('me');

      expect(once.upvotesCount, 3);
      expect(once.isEndorsedBy('me'), isTrue);
      expect(twice.upvotesCount, 3);
      expect(incident.upvotesCount, 2, reason: 'the original report is not mutated');
    });

    test('withoutEndorsementBy removes one endorsement and is idempotent', () {
      final incident = sampleIncident(upvoterIds: ['me', 'voter-2'], upvotesCount: 2);

      final once = incident.withoutEndorsementBy('me');
      final twice = once.withoutEndorsementBy('me');

      expect(once.upvotesCount, 1);
      expect(once.isEndorsedBy('me'), isFalse);
      expect(twice.upvotesCount, 1);
    });

    test('endorsementsMissing counts down to the target and never goes negative', () {
      expect(sampleIncident(upvotesCount: 0).endorsementsMissing, 10);
      expect(sampleIncident(upvotesCount: 7).endorsementsMissing, 3);
      expect(sampleIncident(upvotesCount: 10).endorsementsMissing, 0);
      expect(sampleIncident(upvotesCount: 12).endorsementsMissing, 0);
    });

    test('a report is validated by its status or by its validation date', () {
      expect(sampleIncident().isCommunityValidated, isFalse);
      expect(sampleIncident(status: IncidentStatus.communityValidated).isCommunityValidated, isTrue);
      expect(sampleIncident(validatedAt: DateTime(2026, 11, 15)).isCommunityValidated, isTrue);
    });

    test('a validated report stays validated after the count drops under the target', () {
      final validated = sampleIncident(upvotesCount: 10, validatedAt: DateTime(2026, 11, 15));

      final dropped = validated.withoutEndorsementBy('voter-1');

      expect(dropped.upvotesCount, 9);
      expect(dropped.isCommunityValidated, isTrue);
    });

    test('copyWith keeps every field it was not asked to change', () {
      final incident = sampleIncident(upvotesCount: 3);

      final copy = incident.copyWith(status: IncidentStatus.underReview);

      expect(copy.status, IncidentStatus.underReview);
      expect(copy.title, incident.title);
      expect(copy.upvoterIds, incident.upvoterIds);
      expect(copy.trackingCode, incident.trackingCode);
    });
  });
}

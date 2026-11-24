import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';

import '../../../support/incident_samples.dart';

void main() {
  // sampleIncident() was published on 2026-11-12 00:00 by 'author-1'.
  final published = DateTime(2026, 11, 12);

  group('Incident edit window (RN-03, HU-18)', () {
    test('the author can modify it inside 30 minutes with fewer than 5 endorsements (criterion 1)', () {
      final incident = sampleIncident(upvotesCount: 4);

      expect(incident.canBeModifiedBy('author-1', now: published.add(const Duration(minutes: 29))), isTrue);
    });

    test('at 30 minutes the report is frozen (criterion 4)', () {
      final incident = sampleIncident();

      expect(incident.canBeModifiedBy('author-1', now: published.add(const Duration(minutes: 30, seconds: 1))), isFalse);
      expect(incident.canBeModifiedBy('author-1', now: published.add(const Duration(hours: 2))), isFalse);
    });

    test('with 5 endorsements it is frozen even on the first minute (criterion 4)', () {
      final incident = sampleIncident(upvotesCount: 5);

      expect(incident.canBeModifiedBy('author-1', now: published.add(const Duration(minutes: 1))), isFalse);
    });

    test('4 endorsements still allow it', () {
      expect(
        sampleIncident(upvotesCount: 4).canBeModifiedBy('author-1', now: published.add(const Duration(minutes: 1))),
        isTrue,
      );
    });

    test('only the author can modify: another citizen or a guest cannot', () {
      final incident = sampleIncident();
      final now = published.add(const Duration(minutes: 1));

      expect(incident.canBeModifiedBy('someone-else', now: now), isFalse);
      expect(incident.canBeModifiedBy(null, now: now), isFalse);
    });

    test('the time left counts down and never goes negative', () {
      final incident = sampleIncident();

      expect(incident.editTimeLeft(now: published.add(const Duration(minutes: 10))), const Duration(minutes: 20));
      expect(incident.editTimeLeft(now: published.add(const Duration(hours: 1))), Duration.zero);
      expect(incident.editWindowEndsAt, published.add(const Duration(minutes: 30)));
    });

    test('copyWith changes the editable fields and keeps the tracking code', () {
      final edited = sampleIncident().copyWith(title: 'Nuevo título', severity: IncidentSeverity.critical);

      expect(edited.title, 'Nuevo título');
      expect(edited.severity, IncidentSeverity.critical);
      expect(edited.trackingCode, '#VIG-1001');
      expect(edited.id, 'inc-1');
    });

    test('copyWith can clear the dimensions', () {
      final withDimensions = sampleIncident().copyWith(estimatedDimensions: '1 m');
      expect(withDimensions.estimatedDimensions, '1 m');

      expect(withDimensions.copyWith(clearEstimatedDimensions: true).estimatedDimensions, isNull);
    });
  });
}

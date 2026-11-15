import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';

FeedIncident _feedIncident({String? primaryPhotoUrl, int upvotesCount = 0}) => FeedIncident(
      id: 'inc-1',
      trackingCode: '#VIG-1001',
      title: 'Hueco en la Calle 5',
      neighborhood: 'Centro',
      categoryName: 'Hueco o bache en calzada',
      categoryIcon: 'warning',
      severity: IncidentSeverity.high,
      status: IncidentStatus.reported,
      primaryPhotoUrl: primaryPhotoUrl,
      upvotesCount: upvotesCount,
      coordinates: const Coordinates(latitude: 3.45, longitude: -76.53),
      createdAt: DateTime.utc(2026, 11, 14, 10),
    );

void main() {
  group('FeedIncident', () {
    test('defaults: no photo, no author, no votes and no comments', () {
      final incident = _feedIncident();

      expect(incident.primaryPhotoUrl, isNull);
      expect(incident.reporterName, isNull);
      expect(incident.reporterRankName, isNull);
      expect(incident.upvotesCount, 0);
      expect(incident.commentsCount, 0);
    });

    test('two reports with the same data are equal', () {
      expect(_feedIncident(), _feedIncident());
    });

    test('a change in the votes or in the photo makes it different', () {
      expect(_feedIncident(upvotesCount: 3), isNot(_feedIncident()));
      expect(_feedIncident(primaryPhotoUrl: 'https://example.com/a.jpg'), isNot(_feedIncident()));
    });
  });
}

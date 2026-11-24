import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/data/models/feed_incident_model.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';

Map<String, dynamic> _row({List<Map<String, dynamic>>? photos, Map<String, dynamic>? overrides}) => {
      'id_incident': 'inc-1',
      'tracking_code': '#VIG-1001',
      'title': 'Hueco en la Calle 5',
      'severity': 'HIGH',
      'current_status': 'COMMUNITY_VALIDATED',
      'neighborhood': 'Centro',
      'latitude': 3.45,
      'longitude': -76.53,
      'created_at': '2026-11-14T10:00:00+00:00',
      'category': {'name': 'Hueco o bache en calzada', 'icon': 'warning'},
      'reporter': {
        'full_name': 'Ana Gomez',
        'civic_rank': {'id_rank': 2, 'name': 'Vecino Activo'},
      },
      'incident_photo': photos ?? [],
      'incident_upvote': [
        {'id_user': 'u-1'},
        {'id_user': 'u-2'},
      ],
      'incident_comment': [
        {'id_comment': 'c-1'},
      ],
      ...?overrides,
    };

void main() {
  group('FeedIncidentModel.fromJson', () {
    test('reads the columns, the author and counts the votes and comments', () {
      final model = FeedIncidentModel.fromJson(_row());

      expect(model.id, 'inc-1');
      expect(model.trackingCode, '#VIG-1001');
      expect(model.title, 'Hueco en la Calle 5');
      expect(model.neighborhood, 'Centro');
      expect(model.categoryName, 'Hueco o bache en calzada');
      expect(model.categoryIcon, 'warning');
      expect(model.severity, IncidentSeverity.high);
      expect(model.status, IncidentStatus.communityValidated);
      expect(model.reporterName, 'Ana Gomez');
      expect(model.reporterRankName, 'Vecino Activo');
      expect(model.reporterRankId, 2);
      expect(model.upvotesCount, 2);
      expect(model.commentsCount, 1);
      expect(model.coordinates.latitude, 3.45);
      expect(model.coordinates.longitude, -76.53);
      expect(model.createdAt, DateTime.utc(2026, 11, 14, 10));
    });

    test('reads the description and the address the search of Comunidad needs (HU-20)', () {
      final model = FeedIncidentModel.fromJson(_row(overrides: {
        'description': 'Cráter en el carril derecho.',
        'formatted_address': 'Calle 5 # 38-20',
      }));

      expect(model.description, 'Cráter en el carril derecho.');
      expect(model.formattedAddress, 'Calle 5 # 38-20');
    });

    test('a row without them reads as empty text, so a search never fails on null', () {
      final model = FeedIncidentModel.fromJson(_row());

      expect(model.description, '');
      expect(model.formattedAddress, '');
    });

    test('the select asks for both columns', () {
      expect(FeedIncidentModel.select, contains('description'));
      expect(FeedIncidentModel.select, contains('formatted_address'));
    });

    test('the cover is the primary photo, wherever it is in the list', () {
      final model = FeedIncidentModel.fromJson(_row(photos: [
        {'file_url': 'https://example.com/a.jpg', 'is_primary': false},
        {'file_url': 'https://example.com/b.jpg', 'is_primary': true},
      ]));

      expect(model.primaryPhotoUrl, 'https://example.com/b.jpg');
    });

    test('without a primary photo the cover is the first one', () {
      final model = FeedIncidentModel.fromJson(_row(photos: [
        {'file_url': 'https://example.com/a.jpg', 'is_primary': false},
      ]));

      expect(model.primaryPhotoUrl, 'https://example.com/a.jpg');
    });

    test('a report without photos has no cover', () {
      expect(FeedIncidentModel.fromJson(_row()).primaryPhotoUrl, isNull);
    });

    test('missing joins fall back to safe values instead of failing', () {
      final model = FeedIncidentModel.fromJson(_row(overrides: {
        'category': null,
        'reporter': null,
        'incident_upvote': null,
        'incident_comment': null,
        'severity': null,
        'current_status': null,
      }));

      expect(model.categoryName, 'Otro daño vial');
      expect(model.categoryIcon, 'more_horiz');
      expect(model.reporterName, isNull);
      expect(model.reporterRankName, isNull);
      expect(model.reporterRankId, isNull);
      expect(model.upvotesCount, 0);
      expect(model.commentsCount, 0);
      expect(model.severity, IncidentSeverity.medium);
      expect(model.status, IncidentStatus.reported);
    });
  });
}

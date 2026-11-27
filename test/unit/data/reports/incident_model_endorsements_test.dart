import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/data/models/incident_model.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';

void main() {
  Map<String, dynamic> row({Object? upvotes, Object? validatedAt, String status = 'REPORTED'}) => {
        'id_incident': 'inc-1',
        'tracking_code': '#VIG-1001',
        'id_reporter_user': 'author-1',
        'id_category': 1,
        'title': 'Hueco profundo',
        'description': 'Cráter de más de 20 cm.',
        'severity': 'HIGH',
        'current_status': status,
        'latitude': 3.45,
        'longitude': -76.53,
        'formatted_address': 'Calle 5',
        'neighborhood': 'Tequendama',
        'city': 'Cali',
        'created_at': '2026-11-12T10:00:00Z',
        'incident_upvote': ?upvotes,
        'validated_at': ?validatedAt,
      };

  group('IncidentModel endorsements (HU-15, HU-16)', () {
    test('reads who endorsed the report and counts them', () {
      final model = IncidentModel.fromJson(row(upvotes: [
        {'id_user': 'voter-1'},
        {'id_user': 'voter-2'},
      ]));

      expect(model.upvotesCount, 2);
      expect(model.upvoterIds, ['voter-1', 'voter-2']);
      expect(model.isEndorsedBy('voter-2'), isTrue);
    });

    test('a report without endorsements has an empty list', () {
      final model = IncidentModel.fromJson(row(upvotes: <dynamic>[]));

      expect(model.upvotesCount, 0);
      expect(model.upvoterIds, isEmpty);
    });

    test('a row without the endorsements join still parses', () {
      final model = IncidentModel.fromJson(row());

      expect(model.upvoterIds, isEmpty);
      expect(model.upvotesCount, 0);
    });

    test('reads validated_at and the validated status', () {
      final model = IncidentModel.fromJson(
        row(validatedAt: '2026-11-15T09:30:00Z', status: 'COMMUNITY_VALIDATED'),
      );

      expect(model.validatedAt, DateTime.parse('2026-11-15T09:30:00Z'));
      expect(model.status, IncidentStatus.communityValidated);
      expect(model.isCommunityValidated, isTrue);
    });

    test('a project without the validated_at column still parses', () {
      final model = IncidentModel.fromJson(row());

      expect(model.validatedAt, isNull);
      expect(model.isCommunityValidated, isFalse);
    });
  });
}

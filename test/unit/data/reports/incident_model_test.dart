import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/data/models/incident_model.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';

void main() {
  group('IncidentModel Tests', () {
    test('fromJson and toInsertJson correctly map full incident payload', () {
      final json = {
        'id_incident': 'inc-uuid-1',
        'tracking_code': '#VIG-8492',
        'id_reporter_user': 'user-uuid-1',
        'id_category': 1,
        'title': 'Hueco peligroso en avenida principal',
        'description': 'Profundo hueco que puede generar accidentes de tránsito.',
        'severity': 'HIGH',
        'current_status': 'REPORTED',
        'estimated_dimensions': '~1.5m x 25cm',
        'latitude': 3.4516,
        'longitude': -76.5320,
        'formatted_address': 'Calle 5 con Carrera 44',
        'neighborhood': 'Tequendama',
        'city': 'Cali',
        'created_at': '2026-11-12T12:00:00.000Z',
        'category': {
          'name': 'Hueco o calzada deteriorada',
          'icon': 'pothole',
        },
        'reporter': {
          'full_name': 'Juan Quintero',
          'civic_rank': {'name': 'Observador Urbano'},
        },
        'photos': [
          {
            'id_photo': 'p-1',
            'id_incident': 'inc-uuid-1',
            'file_url': 'https://storage/evidence.jpg',
            'is_primary': true,
            'uploaded_at': '2026-11-12T12:01:00.000Z',
          }
        ],
        'upvotes_count': 5,
        'comments_count': 2,
      };

      final model = IncidentModel.fromJson(json);

      expect(model.id, 'inc-uuid-1');
      expect(model.trackingCode, '#VIG-8492');
      expect(model.reporterName, 'Juan Quintero');
      expect(model.reporterRankName, 'Observador Urbano');
      expect(model.categoryName, 'Hueco o calzada deteriorada');
      expect(model.severity, IncidentSeverity.high);
      expect(model.status, IncidentStatus.reported);
      expect(model.coordinates.latitude, 3.4516);
      expect(model.coordinates.longitude, -76.5320);
      expect(model.photos.length, 1);
      expect(model.primaryPhoto?.fileUrl, 'https://storage/evidence.jpg');
      expect(model.upvotesCount, 5);
      expect(model.commentsCount, 2);

      final insertJson = model.toInsertJson();
      expect(insertJson['tracking_code'], '#VIG-8492');
      expect(insertJson['severity'], 'HIGH');
      expect(insertJson['current_status'], 'REPORTED');
      expect(insertJson['latitude'], 3.4516);
    });
  });
}

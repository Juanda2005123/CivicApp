import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/data/models/profile_model.dart';
import 'package:vigia_app/features/reports/data/models/feed_incident_model.dart';
import 'package:vigia_app/features/reports/data/models/incident_comment_model.dart';
import 'package:vigia_app/features/reports/data/models/incident_model.dart';

void main() {
  group('HU-01 civic privacy in models', () {
    test('ProfileModel reads show_real_name and defaults to true when absent', () {
      final hidden = ProfileModel.fromJson({
        'id_user': 'u1',
        'email': 'a@b.co',
        'full_name': 'Ana Gómez',
        'reference_city': 'Cali',
        'last_city': 'Cali',
        'id_rank': 2,
        'civic_rank': {'name': 'Vecino Activo'},
        'experience_points': 1200,
        'is_active': true,
        'show_real_name': false,
      });
      expect(hidden.showRealName, isFalse);

      final defaulted = ProfileModel.fromJson({
        'id_user': 'u1',
        'email': 'a@b.co',
        'full_name': 'Ana Gómez',
        'reference_city': 'Cali',
        'last_city': 'Cali',
        'id_rank': 1,
        'experience_points': 0,
        'is_active': true,
      });
      expect(defaulted.showRealName, isTrue);
    });

    test('FeedIncidentModel hides reporterName when show_real_name is false and keeps rank', () {
      final json = {
        'id_incident': 'inc-1',
        'tracking_code': '#VIG-1001',
        'title': 'Hueco en la 5ta',
        'severity': 'HIGH',
        'current_status': 'REPORTED',
        'neighborhood': 'San Fernando',
        'description': 'Hueco profundo',
        'formatted_address': 'Calle 5 # 34-10',
        'latitude': 3.43,
        'longitude': -76.54,
        'created_at': '2026-11-20T10:00:00Z',
        'category': {'name': 'Bache', 'icon': 'warning'},
        'reporter': {
          'full_name': 'Ana Gómez',
          'show_real_name': false,
          'civic_rank': {'id_rank': 3, 'name': 'Guardián Vial'},
        },
        'incident_photo': [],
        'incident_upvote': [],
        'incident_comment': [],
      };

      final model = FeedIncidentModel.fromJson(json);
      expect(model.reporterName, isNull);
      expect(model.reporterRankName, 'Guardián Vial');
      expect(model.reporterRankId, 3);
    });

    test('IncidentModel hides reporterName when show_real_name is false and shows it when true', () {
      Map<String, dynamic> baseJson(bool showRealName) => {
            'id_incident': 'inc-1',
            'tracking_code': '#VIG-1001',
            'id_reporter_user': 'u1',
            'id_category': 1,
            'title': 'Hueco en la 5ta',
            'description': 'Hueco profundo',
            'severity': 'HIGH',
            'current_status': 'REPORTED',
            'latitude': 3.43,
            'longitude': -76.54,
            'formatted_address': 'Calle 5 # 34-10',
            'neighborhood': 'San Fernando',
            'city': 'Cali',
            'created_at': '2026-11-20T10:00:00Z',
            'updated_at': '2026-11-20T10:00:00Z',
            'reporter': {
              'full_name': 'Ana Gómez',
              'show_real_name': showRealName,
              'civic_rank': {'name': 'Vecino Activo'},
            },
          };

      final hidden = IncidentModel.fromJson(baseJson(false));
      expect(hidden.reporterName, isNull);
      expect(hidden.reporterRankName, 'Vecino Activo');

      final visible = IncidentModel.fromJson(baseJson(true));
      expect(visible.reporterName, 'Ana Gómez');
    });

    test('IncidentCommentModel hides authorName when show_real_name is false and keeps rank', () {
      final json = {
        'id_comment': 'c1',
        'id_incident': 'inc-1',
        'id_user': 'u1',
        'content': 'Sigue igual',
        'created_at': '2026-11-20T10:05:00Z',
        'author': {
          'full_name': 'Ana Gómez',
          'show_real_name': false,
          'id_rank': 2,
          'civic_rank': {'name': 'Vecino Activo'},
        },
      };

      final model = IncidentCommentModel.fromJson(json);
      expect(model.authorName, isNull);
      expect(model.authorRankLevel, 2);
      expect(model.authorRankName, 'Vecino Activo');
    });
  });
}

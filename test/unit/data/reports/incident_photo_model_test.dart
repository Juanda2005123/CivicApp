import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/data/models/incident_photo_model.dart';

void main() {
  group('IncidentPhotoModel Tests', () {
    test('fromJson and toJson map photo evidence data correctly', () {
      final json = {
        'id_photo': 'photo-uuid-1',
        'id_incident': 'incident-uuid-1',
        'file_url': 'https://storage.supabase.co/v1/evidence.jpg',
        'is_primary': true,
        'uploaded_at': '2026-11-12T10:00:00.000Z',
      };

      final model = IncidentPhotoModel.fromJson(json);

      expect(model.id, 'photo-uuid-1');
      expect(model.incidentId, 'incident-uuid-1');
      expect(model.fileUrl, 'https://storage.supabase.co/v1/evidence.jpg');
      expect(model.isPrimary, true);
      expect(model.uploadedAt, DateTime.parse('2026-11-12T10:00:00.000Z'));

      final mappedBack = model.toJson();
      expect(mappedBack['id_photo'], 'photo-uuid-1');
      expect(mappedBack['is_primary'], true);
    });
  });
}

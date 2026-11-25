import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/data/models/incident_comment_model.dart';

void main() {
  test('IncidentCommentModel reads author profile_picture_url into authorAvatarUrl', () {
    final withAvatar = IncidentCommentModel.fromJson({
      'id_comment': 'c1',
      'id_incident': 'inc-1',
      'id_user': 'u1',
      'content': 'Buen aporte',
      'created_at': '2026-11-20T10:00:00Z',
      'author': {
        'full_name': 'Ana Gómez',
        'id_rank': 2,
        'profile_picture_url': 'https://example.com/avatars/u1/pic.jpg',
        'civic_rank': {'name': 'Vecino Activo'},
      },
    });
    expect(withAvatar.authorAvatarUrl, 'https://example.com/avatars/u1/pic.jpg');

    final withoutAvatar = IncidentCommentModel.fromJson({
      'id_comment': 'c2',
      'id_incident': 'inc-1',
      'id_user': 'u2',
      'content': 'Sin foto',
      'created_at': '2026-11-20T10:05:00Z',
      'author': {
        'full_name': 'Luis Pérez',
        'id_rank': 1,
        'civic_rank': {'name': 'Observador Urbano'},
      },
    });
    expect(withoutAvatar.authorAvatarUrl, isNull);
  });
}

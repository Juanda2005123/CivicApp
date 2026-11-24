import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/data/models/incident_comment_model.dart';

void main() {
  Map<String, dynamic> row({Object? photo, Object? author, String? content = 'Sigue igual.'}) => {
        'id_comment': 'c-1',
        'id_incident': 'inc-1',
        'id_user': 'user-1',
        'content': content,
        'created_at': '2026-11-16T10:00:00Z',
        'author': author ??
            {
              'full_name': 'Ana Vecina',
              'id_rank': 3,
              'civic_rank': {'name': 'Guardián Vial'},
            },
        'comment_photo': photo,
      };

  group('IncidentCommentModel (HU-17)', () {
    test('reads the author, their rank and the text', () {
      final model = IncidentCommentModel.fromJson(row());

      expect(model.id, 'c-1');
      expect(model.incidentId, 'inc-1');
      expect(model.authorId, 'user-1');
      expect(model.authorName, 'Ana Vecina');
      expect(model.authorRankLevel, 3);
      expect(model.authorRankName, 'Guardián Vial');
      expect(model.text, 'Sigue igual.');
      expect(model.createdAt, DateTime.parse('2026-11-16T10:00:00Z'));
      expect(model.hasPhoto, isFalse);
    });

    test('reads the photo whether PostgREST answers an object, a list or null', () {
      expect(IncidentCommentModel.fromJson(row(photo: {'file_url': 'https://x/p.jpg'})).photoUrl, 'https://x/p.jpg');
      expect(
        IncidentCommentModel.fromJson(row(photo: [
          {'file_url': 'https://x/q.jpg'}
        ])).photoUrl,
        'https://x/q.jpg',
      );
      expect(IncidentCommentModel.fromJson(row(photo: <dynamic>[])).photoUrl, isNull);
      expect(IncidentCommentModel.fromJson(row(photo: null)).photoUrl, isNull);
    });

    test('a photo-only comment has an empty text', () {
      final model = IncidentCommentModel.fromJson(row(content: '', photo: {'file_url': 'https://x/p.jpg'}));

      expect(model.text, isEmpty);
      expect(model.hasText, isFalse);
      expect(model.hasPhoto, isTrue);
    });

    test('a missing author or rank falls back to level 1', () {
      final model = IncidentCommentModel.fromJson(row(author: <String, dynamic>{}));

      expect(model.authorName, isNull);
      expect(model.authorRankLevel, 1);
      expect(model.authorRankName, isNull);
    });

    test('keeps the rank level between 1 and 4', () {
      final model = IncidentCommentModel.fromJson(row(author: {'full_name': 'X', 'id_rank': 9}));

      expect(model.authorRankLevel, 4);
    });
  });
}

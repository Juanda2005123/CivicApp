import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/data/models/user_model.dart';
import 'package:vigia_app/features/auth/domain/entities/user.dart';

void main() {
  group('UserModel Serialization & Mapping', () {
    test('Correctly maps JSON from English schema.sql columns to UserModel and User Entity', () {
      final json = {
        'id_user': '9d26be1f-8511-4314-8ab2-960dd82d13f0',
        'email': 'juanm@fgmail.com',
        'full_name': 'Juan David Quintero',
        'id_rank': 1,
        'reference_city': 'Cali',
        'last_city': 'Cali',
        'experience_points': 150,
        'is_active': true,
      };

      final model = UserModel.fromJson(json);

      expect(model.id, '9d26be1f-8511-4314-8ab2-960dd82d13f0');
      expect(model.email, 'juanm@fgmail.com');
      expect(model.fullName, 'Juan David Quintero');
      expect(model.rankId, 1);
      expect(model.rankName, 'Urban Observer');
      expect(model.cityName, 'Cali');
      expect(model.reputationPoints, 150);
      expect(model.isActive, true);

      final entity = model.toEntity();
      expect(entity, isA<User>());
      expect(entity.id, model.id);
      expect(entity.email, model.email);
    });

    test('Correctly handles nested joins from civic_rank and coverage_city in English', () {
      final json = {
        'id_user': 'uuid-1234',
        'email': 'citizen@vigia.co',
        'full_name': 'Maria Camila Gomez',
        'residence_city_id': 1,
        'id_rank': 2,
        'experience_points': 500,
        'is_active': true,
        'civic_rank': {
          'id_rank': 2,
          'name': 'Active Neighbor',
        },
        'coverage_city': {
          'id_city': 1,
          'name': 'Cali',
          'department': 'Valle del Cauca',
        },
      };

      final model = UserModel.fromJson(json);

      expect(model.rankName, 'Active Neighbor');
      expect(model.cityName, 'Cali (Valle del Cauca)');
      expect(model.reputationPoints, 500);
    });

    test('toJson generates expected map matching user_profile table', () {
      const model = UserModel(
        id: 'user-abc',
        email: 'test@vigia.co',
        fullName: 'Test User',
        residenceCityId: 1,
        cityName: 'Cali',
        rankId: 1,
        reputationPoints: 0,
        isActive: true,
      );

      final json = model.toJson();

      expect(json['id_user'], 'user-abc');
      expect(json['email'], 'test@vigia.co');
      expect(json['full_name'], 'Test User');
      expect(json['is_active'], true);
    });
  });
}

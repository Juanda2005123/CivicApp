import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/data/models/profile_model.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';

void main() {
  group('ProfileModel', () {
    test('fromJson reads the user_profile columns and the joined rank name', () {
      final model = ProfileModel.fromJson({
        'id_user': 'uid-1',
        'id_rank': 2,
        'full_name': 'Ana Gomez',
        'email': 'ana@example.com',
        'reference_city': 'Cali',
        'last_city': 'Cali',
        'experience_points': 120,
        'is_active': true,
        'civic_rank': {'name': 'Active Citizen'},
      });

      expect(model.id, 'uid-1');
      expect(model.fullName, 'Ana Gomez');
      expect(model.cityName, 'Cali');
      expect(model.rankId, 2);
      expect(model.rankName, 'Active Citizen');
      expect(model.experiencePoints, 120);
    });

    test('fromJson falls back to the default rank name when the join is missing', () {
      final model = ProfileModel.fromJson({
        'id_user': 'uid-1',
        'id_rank': 1,
        'full_name': 'Ana Gomez',
        'email': 'ana@example.com',
        'reference_city': 'Cali',
        'last_city': 'Cali',
        'experience_points': 0,
        'is_active': true,
      });

      expect(model.rankName, 'Observador Urbano');
    });

    test('toInsertJson sets every NOT NULL column of user_profile', () {
      final json = ProfileModel.fromEntity(const Profile(
        id: 'uid-1',
        email: 'ana@example.com',
        fullName: 'Ana Gomez',
        cityName: 'Cali',
      )).toInsertJson();

      expect(json, {
        'id_user': 'uid-1',
        'id_rank': 1,
        'full_name': 'Ana Gomez',
        'email': 'ana@example.com',
        'reference_city': 'Cali',
        'last_city': 'Cali',
        'experience_points': 0,
        'is_active': true,
      });
      expect(json.containsKey('residence_city_id'), isFalse);
    });
  });
}

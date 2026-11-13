import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/data/models/incident_category_model.dart';

void main() {
  group('IncidentCategoryModel Tests', () {
    test('fromJson and toJson map category data correctly', () {
      final json = {
        'id_category': 1,
        'name': 'Hueco o calzada deteriorada',
        'icon': 'pothole',
        'description': 'Huecos, grietas y fallas en el pavimento.',
      };

      final model = IncidentCategoryModel.fromJson(json);

      expect(model.id, 1);
      expect(model.name, 'Hueco o calzada deteriorada');
      expect(model.icon, 'pothole');
      expect(model.description, 'Huecos, grietas y fallas en el pavimento.');

      final mappedBack = model.toJson();
      expect(mappedBack['id_category'], 1);
      expect(mappedBack['name'], 'Hueco o calzada deteriorada');
    });
  });
}

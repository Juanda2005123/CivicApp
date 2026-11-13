import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_category.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_categories_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_incident_by_id_usecase.dart';

import '../../../support/fakes.dart';

void main() {
  group('GetCategoriesUseCase and GetIncidentByIdUseCase Tests', () {
    test('GetCategoriesUseCase returns category list from repository', () async {
      final categoryRepo = FakeCategoryRepository(categories: [
        const IncidentCategory(id: 1, name: 'Hueco', icon: 'pothole'),
        const IncidentCategory(id: 2, name: 'Semáforo', icon: 'traffic_light'),
      ]);
      final useCase = GetCategoriesUseCase(categoryRepo);

      final result = await useCase();

      expect(result.length, 2);
      expect(result[0].name, 'Hueco');
      expect(result[1].name, 'Semáforo');
    });

    test('GetIncidentByIdUseCase returns incident by id or tracking code', () async {
      final incidentRepo = FakeIncidentRepository();
      final testIncident = Incident(
        id: 'inc-100',
        trackingCode: '#VIG-1234',
        reporterId: 'user-1',
        categoryId: 1,
        title: 'Bache peligroso',
        description: 'Descripción de prueba detallada',
        severity: IncidentSeverity.critical,
        coordinates: const Coordinates(latitude: 3.45, longitude: -76.53),
        formattedAddress: 'Av 6N # 20-00',
        neighborhood: 'Granada',
        city: 'Cali',
        createdAt: DateTime(2026, 11, 12),
      );
      incidentRepo.stored['#VIG-1234'] = testIncident;
      final useCase = GetIncidentByIdUseCase(incidentRepo);

      final found = await useCase('#VIG-1234');

      expect(found.id, 'inc-100');
      expect(found.title, 'Bache peligroso');
      expect(found.severity, IncidentSeverity.critical);
    });

    test('GetIncidentByIdUseCase throws when identifier is empty', () async {
      final incidentRepo = FakeIncidentRepository();
      final useCase = GetIncidentByIdUseCase(incidentRepo);

      expect(() => useCase('   '), throwsException);
    });
  });
}

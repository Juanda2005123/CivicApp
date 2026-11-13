import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/nearby_incident.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_nearby_incidents_usecase.dart';

import '../../../support/fakes.dart';

void main() {
  group('GetNearbyIncidentsUseCase Tests', () {
    late FakeIncidentRepository repository;
    late GetNearbyIncidentsUseCase useCase;

    setUp(() {
      repository = FakeIncidentRepository();
      useCase = GetNearbyIncidentsUseCase(repository);
    });

    test('returns nearby duplicates when coordinates are valid', () async {
      repository.nearbyToReturn = [
        const NearbyIncident(
          id: 'incident-99',
          trackingCode: '#VIG-9999',
          title: 'Hueco grande',
          categoryId: 1,
          categoryName: 'Huecos y calzada',
          severity: 'HIGH',
          distanceInMeters: 45.2,
          upvotesCount: 3,
        ),
      ];

      final results = await useCase(
        coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
        categoryId: 1,
      );

      expect(results.length, 1);
      expect(results.first.title, 'Hueco grande');
      expect(repository.calls, contains('incident.getNearby'));
    });

    test('throws exception when coordinates are outside Colombia', () async {
      expect(
        () => useCase(
          coordinates: const Coordinates(latitude: 48.8566, longitude: 2.3522), // Paris
          categoryId: 1,
        ),
        throwsA(predicate((e) => e.toString().contains('territorio colombiano'))),
      );
      expect(repository.calls, isEmpty);
    });
  });
}

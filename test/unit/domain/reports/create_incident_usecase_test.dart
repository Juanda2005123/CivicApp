import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:vigia_app/features/reports/domain/usecases/create_incident_usecase.dart';

import '../../../support/fakes.dart';

void main() {
  group('CreateIncidentUseCase Tests', () {
    late FakeIncidentRepository repository;
    late CreateIncidentUseCase useCase;

    setUp(() {
      repository = FakeIncidentRepository();
      useCase = CreateIncidentUseCase(repository);
    });

    test('creates incident with valid fields and delegates to repository', () async {
      final photo = PickedPhoto(
        bytes: Uint8List(200),
        extension: 'webp',
        sizeInBytes: 2048,
      );

      final incident = await useCase(
        reporterId: 'user-123',
        categoryId: 1,
        title: 'Hueco profundo en la vía principal',
        description: 'Bache de gran tamaño que está causando daños a los vehículos.',
        severity: IncidentSeverity.high,
        estimatedDimensions: '~1m x 30cm',
        coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
        formattedAddress: 'Calle 5 con Carrera 44',
        neighborhood: 'Tequendama',
        city: 'Cali',
        photos: [photo],
      );

      expect(incident.id, startsWith('incident-'));
      expect(incident.trackingCode, startsWith('#VIG-'));
      expect(incident.title, 'Hueco profundo en la vía principal');
      expect(incident.severity, IncidentSeverity.high);
      expect(incident.photos.length, 1);
      expect(repository.calls, contains('incident.create'));
    });

    test('throws exception when user is not authenticated', () async {
      expect(
        () => useCase(
          reporterId: '   ',
          categoryId: 1,
          title: 'Hueco profundo',
          description: 'Descripción válida de más de diez caracteres.',
          severity: IncidentSeverity.medium,
          coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
          formattedAddress: 'Calle 5',
          neighborhood: 'San Fernando',
          city: 'Cali',
          photos: [],
        ),
        throwsA(predicate((e) => e.toString().contains('iniciar sesión'))),
      );
    });

    test('validates title and description constraints before calling repository', () async {
      expect(
        () => useCase(
          reporterId: 'user-123',
          categoryId: 1,
          title: 'abc', // too short
          description: 'Descripción válida de más de diez caracteres.',
          severity: IncidentSeverity.medium,
          coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
          formattedAddress: 'Calle 5',
          neighborhood: 'San Fernando',
          city: 'Cali',
          photos: [],
        ),
        throwsA(predicate((e) => e.toString().contains('al menos 5'))),
      );
      expect(repository.calls, isEmpty);
    });
  });
}

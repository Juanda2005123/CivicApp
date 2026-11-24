import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_photo.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:vigia_app/features/reports/domain/usecases/delete_incident_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/update_incident_usecase.dart';

import '../../../support/fakes.dart';
import '../../../support/incident_samples.dart';

IncidentPhoto _photo(String id, {bool primary = false}) => IncidentPhoto(
      id: id,
      incidentId: 'inc-1',
      fileUrl: 'https://example.com/$id.jpg',
      isPrimary: primary,
      uploadedAt: DateTime(2026, 11, 12),
    );

PickedPhoto _picked({String extension = 'jpg', int size = 1000}) =>
    PickedPhoto(bytes: Uint8List(8), extension: extension, sizeInBytes: size);

void main() {
  late FakeIncidentRepository repository;
  late Incident incident;

  setUp(() {
    repository = FakeIncidentRepository();
    incident = sampleIncident().copyWith(photos: [_photo('p1', primary: true), _photo('p2')]);
    repository.stored[incident.id] = incident;
  });

  Future<Incident> edit({
    String userId = 'author-1',
    String title = 'Hueco muy profundo',
    String description = 'Ahora el hueco ocupa todo el carril.',
    String? dimensions = '  1 m  ',
    List<IncidentPhoto>? kept,
    List<PickedPhoto> added = const [],
  }) {
    return UpdateIncidentUseCase(repository)(
      incident: incident,
      userId: userId,
      categoryId: 2,
      title: title,
      description: description,
      severity: IncidentSeverity.critical,
      estimatedDimensions: dimensions,
      keptPhotos: kept ?? incident.photos,
      addedPhotos: added,
    );
  }

  group('UpdateIncidentUseCase (HU-18, criterion 2)', () {
    test('saves the trimmed edit and keeps the tracking code', () async {
      final updated = await edit(title: '  Hueco muy profundo  ');

      expect(updated.title, 'Hueco muy profundo');
      expect(updated.estimatedDimensions, '1 m');
      expect(updated.categoryId, 2);
      expect(updated.severity, IncidentSeverity.critical);
      expect(updated.trackingCode, '#VIG-1001');
      expect(repository.calls, contains('incident.update'));
    });

    test('empty dimensions are saved as none', () async {
      final updated = await edit(dimensions: '   ');

      expect(updated.estimatedDimensions, isNull);
    });

    test('applies the same rules as the first publication: title and description', () async {
      await expectLater(edit(title: 'Hey'), throwsA(predicate((e) => e.toString().contains('al menos 5 caracteres'))));
      await expectLater(edit(description: 'corto'), throwsA(predicate((e) => e.toString().contains('al menos 10 caracteres'))));
      expect(repository.calls, isNot(contains('incident.update')));
    });

    test('rejects an invalid new photo (format or size)', () async {
      await expectLater(
        edit(added: [_picked(extension: 'gif')]),
        throwsA(predicate((e) => e.toString().contains('JPG, PNG o WebP'))),
      );
      await expectLater(
        edit(added: [_picked(size: 6 * 1024 * 1024)]),
        throwsA(predicate((e) => e.toString().contains('5 MB'))),
      );
    });

    test('rejects more than 3 photos between the kept and the new ones', () async {
      await expectLater(
        edit(added: [_picked(), _picked()]),
        throwsA(predicate((e) => e.toString().contains('más de 3 fotos'))),
      );
    });

    test('the photos not kept are the ones removed', () async {
      final updated = await edit(kept: [incident.photos.first], added: [_picked()]);

      expect(updated.photos.map((p) => p.id), ['p1', 'new-photo-3']);
    });

    test('only the author edits', () async {
      await expectLater(
        edit(userId: 'someone-else'),
        throwsA(predicate((e) => e.toString().contains('Solo quien publicó el reporte'))),
      );
      expect(repository.calls, isNot(contains('incident.update')));
    });

    test('the server message of a frozen report reaches the caller', () async {
      repository.updateError = Exception('Este reporte ya no se puede modificar ni eliminar: pasaron más de 30 minutos o tiene 5 apoyos o más.');

      await expectLater(edit(), throwsA(predicate((e) => e.toString().contains('pasaron más de 30 minutos'))));
    });
  });

  group('DeleteIncidentUseCase (HU-18, criterion 3)', () {
    test('deletes the report of the author', () async {
      await DeleteIncidentUseCase(repository)(incident: incident, userId: 'author-1');

      expect(repository.deletedIds, ['inc-1']);
    });

    test('nobody else deletes it', () async {
      await expectLater(
        DeleteIncidentUseCase(repository)(incident: incident, userId: 'someone-else'),
        throwsA(predicate((e) => e.toString().contains('Solo quien publicó el reporte'))),
      );
      expect(repository.deletedIds, isEmpty);
    });

    test('the server refusal after the window reaches the caller (criterion 5)', () async {
      repository.deleteError = Exception('Este reporte ya no se puede modificar ni eliminar: pasaron más de 30 minutos o tiene 5 apoyos o más.');

      await expectLater(
        DeleteIncidentUseCase(repository)(incident: incident, userId: 'author-1'),
        throwsA(predicate((e) => e.toString().contains('pasaron más de 30 minutos'))),
      );
    });
  });
}

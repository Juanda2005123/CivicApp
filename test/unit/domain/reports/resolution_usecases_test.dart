import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_resolution.dart';
import 'package:vigia_app/features/reports/domain/usecases/accept_resolution_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/confirm_resolution_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_active_resolution_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/object_resolution_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/pick_resolution_photo_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/pick_photo_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/propose_resolution_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/reject_resolution_usecase.dart';

import '../../../support/comment_samples.dart';
import '../../../support/fake_resolution_repository.dart';
import '../../../support/fakes.dart';
import '../../../support/incident_samples.dart';
import '../../../support/resolution_samples.dart';

Matcher failsWith(String text) => throwsA(predicate((e) => e.toString().contains(text)));

void main() {
  late FakeResolutionRepository repository;
  final now = DateTime(2026, 11, 21, 9);

  setUp(() {
    repository = FakeResolutionRepository();
  });

  group('GetActiveResolutionUseCase', () {
    test('returns the open proposal of the report', () async {
      repository.active['inc-1'] = sampleResolution();

      final resolution = await GetActiveResolutionUseCase(repository)('inc-1', now: now);

      expect(resolution?.id, 'res-1');
    });

    test('a proposal whose 7 days passed counts as none', () async {
      repository.active['inc-1'] = sampleResolution(proposedAt: now.subtract(const Duration(days: 8)));

      expect(await GetActiveResolutionUseCase(repository)('inc-1', now: now), isNull);
    });
  });

  group('ProposeResolutionUseCase (criterion 1)', () {
    late ProposeResolutionUseCase propose;

    setUp(() {
      propose = ProposeResolutionUseCase(repository);
    });

    test('sends the photo and the trimmed description', () async {
      final photo = samplePhoto();

      await propose(
        incident: sampleIncident(),
        userId: 'neighbor-1',
        photo: photo,
        description: '  Ya taparon el hueco.  ',
      );

      expect(repository.calls, ['resolution.propose']);
      expect(repository.lastPhoto, photo);
      expect(repository.lastDescription, 'Ya taparon el hueco.');
    });

    test('the photo is mandatory', () {
      expect(
        () => propose(incident: sampleIncident(), userId: 'neighbor-1', photo: null, description: 'Ya taparon el hueco.'),
        failsWith('Adjunta una foto'),
      );
      expect(repository.calls, isEmpty);
    });

    test('the description needs at least 10 characters and at most 500', () {
      expect(
        () => propose(incident: sampleIncident(), userId: 'neighbor-1', photo: samplePhoto(), description: ' Listo '),
        failsWith('mínimo 10'),
      );
      expect(
        () => propose(incident: sampleIncident(), userId: 'neighbor-1', photo: samplePhoto(), description: 'a' * 501),
        failsWith('500 caracteres'),
      );
    });

    test('a guest and a resolved report are refused', () {
      expect(
        () => propose(incident: sampleIncident(), userId: ' ', photo: samplePhoto(), description: 'Ya taparon el hueco.'),
        failsWith('iniciar sesión'),
      );
      expect(
        () => propose(
          incident: sampleIncident(status: IncidentStatus.resolved),
          userId: 'neighbor-1',
          photo: samplePhoto(),
          description: 'Ya taparon el hueco.',
        ),
        failsWith('ya está resuelto'),
      );
    });

    test('a photo that is too big is refused before uploading', () {
      expect(
        () => propose(
          incident: sampleIncident(),
          userId: 'neighbor-1',
          photo: samplePhoto(sizeInBytes: 6 * 1024 * 1024),
          description: 'Ya taparon el hueco.',
        ),
        throwsA(isA<Exception>()),
      );
      expect(repository.calls, isEmpty);
    });
  });

  group('PickResolutionPhotoUseCase', () {
    test('returns the picked photo and null when cancelled', () async {
      final photo = samplePhoto();
      final pick = PickResolutionPhotoUseCase(PickPhotoUseCase(FakePhotoPickerRepository(photoToReturn: photo)));
      final cancel = PickResolutionPhotoUseCase(PickPhotoUseCase(FakePhotoPickerRepository()));

      expect(await pick(fromCamera: true), photo);
      expect(await cancel(), isNull);
    });

    test('refuses a wrong format at once', () {
      final pick = PickResolutionPhotoUseCase(
          PickPhotoUseCase(FakePhotoPickerRepository(photoToReturn: samplePhoto(extension: 'gif'))));

      expect(() => pick(), throwsA(isA<Exception>()));
    });
  });

  group('Confirm and object (criteria 4 and 5)', () {
    test('a neighbor confirms and objects', () async {
      final resolution = sampleResolution(proposedAt: now);

      await ConfirmResolutionUseCase(repository)(
          resolution: resolution, reporterId: 'author-1', userId: 'voter-1', now: now);
      await ObjectResolutionUseCase(repository)(
          resolution: resolution, reporterId: 'author-1', userId: 'voter-2', now: now);

      expect(repository.calls, ['resolution.confirm', 'resolution.object']);
    });

    test('the proponent, the author and a second vote are refused', () {
      final confirm = ConfirmResolutionUseCase(repository);
      final resolution = sampleResolution(proposedAt: now, objectorIds: ['voter-1']);

      expect(() => confirm(resolution: resolution, reporterId: 'author-1', userId: 'neighbor-1', now: now),
          failsWith('tu propia propuesta'));
      expect(() => confirm(resolution: resolution, reporterId: 'author-1', userId: 'author-1', now: now),
          failsWith('acepta o rechaza'));
      expect(() => confirm(resolution: resolution, reporterId: 'author-1', userId: 'voter-1', now: now),
          failsWith('Ya votaste'));
      expect(repository.calls, isEmpty);
    });

    test('an expired proposal and a guest are refused', () {
      final object = ObjectResolutionUseCase(repository);

      expect(
        () => object(
          resolution: sampleResolution(proposedAt: now.subtract(const Duration(days: 8))),
          reporterId: 'author-1',
          userId: 'voter-1',
          now: now,
        ),
        failsWith('ya no está en verificación'),
      );
      expect(
        () => object(resolution: sampleResolution(proposedAt: now), reporterId: 'author-1', userId: '', now: now),
        failsWith('iniciar sesión'),
      );
    });
  });

  group('Accept and reject (RN-11)', () {
    test('the author accepts', () async {
      await AcceptResolutionUseCase(repository)(
          resolution: sampleResolution(proposedAt: now), reporterId: 'author-1', userId: 'author-1', now: now);

      expect(repository.calls, ['resolution.accept']);
    });

    test('the author rejects with a trimmed reason', () async {
      await RejectResolutionUseCase(repository)(
        resolution: sampleResolution(proposedAt: now),
        reporterId: 'author-1',
        userId: 'author-1',
        reason: '  Solo le echaron tierra.  ',
        now: now,
      );

      expect(repository.lastReason, 'Solo le echaron tierra.');
    });

    test('rejecting needs a reason of at least 10 characters', () {
      expect(
        () => RejectResolutionUseCase(repository)(
          resolution: sampleResolution(proposedAt: now),
          reporterId: 'author-1',
          userId: 'author-1',
          reason: 'No',
          now: now,
        ),
        failsWith('mínimo 10'),
      );
    });

    test('nobody but the author decides, and never on a closed proposal', () {
      expect(
        () => AcceptResolutionUseCase(repository)(
            resolution: sampleResolution(proposedAt: now), reporterId: 'author-1', userId: 'voter-1', now: now),
        failsWith('Solo quien publicó'),
      );
      expect(
        () => AcceptResolutionUseCase(repository)(
          resolution: sampleResolution(status: ResolutionStatus.expired, proposedAt: now),
          reporterId: 'author-1',
          userId: 'author-1',
          now: now,
        ),
        failsWith('ya no está en verificación'),
      );
      expect(repository.calls, isEmpty);
    });
  });
}

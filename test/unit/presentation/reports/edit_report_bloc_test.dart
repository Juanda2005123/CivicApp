import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_photo.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:vigia_app/features/reports/ui/bloc/edit_report_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/edit_report_event.dart';
import 'package:vigia_app/features/reports/ui/bloc/edit_report_state.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/edit_bloc_factory.dart';
import '../../../support/fakes.dart';
import '../../../support/incident_samples.dart';

IncidentPhoto _photo(String id) => IncidentPhoto(
      id: id,
      incidentId: 'inc-1',
      fileUrl: 'https://example.com/$id.jpg',
      isPrimary: id == 'p1',
      uploadedAt: DateTime(2026, 11, 12),
    );

PickedPhoto _picked({String extension = 'jpg', int size = 1000}) =>
    PickedPhoto(bytes: Uint8List(8), extension: extension, sizeInBytes: size);

void main() {
  late FakeIncidentRepository repository;
  late FakePhotoPickerRepository picker;
  late Incident incident;
  late EditReportBloc bloc;

  setUp(() {
    repository = FakeIncidentRepository();
    picker = FakePhotoPickerRepository();
    incident = sampleIncident(reporterId: 'me').copyWith(photos: [_photo('p1'), _photo('p2')]);
    repository.stored[incident.id] = incident;
    bloc = buildEditBloc(repository, picker: picker);
  });

  tearDown(() => bloc.close());

  Future<void> open() async {
    bloc.add(EditReportStarted(incident));
    await pumpEventQueue();
  }

  group('EditReportBloc (HU-18)', () {
    test('opens with the values of the report and the categories loaded', () async {
      final states = await emittedStates(bloc, EditReportStarted(incident));

      expect(states.first.status, EditReportStatus.loading);
      expect(states.last.status, EditReportStatus.ready);
      expect(states.last.categoryId, incident.categoryId);
      expect(states.last.severity, incident.severity);
      expect(states.last.keptPhotos.map((p) => p.id), ['p1', 'p2']);
      expect(states.last.categories, hasLength(2));
    });

    test('categories that cannot load are a failure with the message', () async {
      bloc = buildEditBloc(repository, categories: FakeCategoryRepository(error: Exception('Sin conexión')));

      final states = await emittedStates(bloc, EditReportStarted(incident));

      expect(states.last.status, EditReportStatus.failure);
      expect(states.last.errorMessage, 'Sin conexión');
    });

    test('changing the category and the severity updates the form', () async {
      await open();
      bloc.add(const EditCategorySelected(2));
      bloc.add(const EditSeveritySelected(IncidentSeverity.critical));
      await pumpEventQueue();

      expect(bloc.state.categoryId, 2);
      expect(bloc.state.severity, IncidentSeverity.critical);
    });

    test('removing a photo the report has takes it out of the kept ones', () async {
      await open();
      bloc.add(const EditKeptPhotoRemoved('p1'));
      await pumpEventQueue();

      expect(bloc.state.keptPhotos.map((p) => p.id), ['p2']);
    });

    test('a valid photo is added; the limit is 3 between kept and new', () async {
      await open();
      picker.photoToReturn = _picked();

      bloc.add(const EditPhotoPickRequested(fromCamera: false));
      await pumpEventQueue();
      expect(bloc.state.addedPhotos, hasLength(1));
      expect(bloc.state.canAddPhoto, isFalse);

      bloc.add(const EditPhotoPickRequested(fromCamera: false));
      await pumpEventQueue();
      expect(bloc.state.addedPhotos, hasLength(1));
      expect(bloc.state.errorMessage, 'Ya has alcanzado el límite de 3 fotos.');
    });

    test('a bad photo is refused with the reason and the photos already chosen stay', () async {
      await open();
      bloc.add(const EditKeptPhotoRemoved('p2'));
      picker.photoToReturn = _picked();
      bloc.add(const EditPhotoPickRequested(fromCamera: false));
      await pumpEventQueue();

      picker.photoToReturn = _picked(extension: 'gif');
      bloc.add(const EditPhotoPickRequested(fromCamera: false));
      await pumpEventQueue();

      expect(bloc.state.addedPhotos, hasLength(1));
      expect(bloc.state.errorMessage, contains('JPG, PNG o WebP'));
    });

    test('removing an added photo by position', () async {
      await open();
      bloc.add(const EditKeptPhotoRemoved('p2'));
      picker.photoToReturn = _picked();
      bloc.add(const EditPhotoPickRequested(fromCamera: true));
      await pumpEventQueue();

      bloc.add(const EditAddedPhotoRemoved(0));
      await pumpEventQueue();

      expect(bloc.state.addedPhotos, isEmpty);
    });

    test('saving sends the form to the repository and ends as saved with the updated report', () async {
      await open();
      bloc.add(const EditCategorySelected(2));
      await pumpEventQueue();

      final states = await emittedStates(
        bloc,
        const EditSubmitted(title: 'Hueco muy profundo', description: 'Ahora ocupa todo el carril.'),
      );

      expect(states.first.status, EditReportStatus.saving);
      expect(states.last.status, EditReportStatus.saved);
      expect(states.last.savedIncident?.title, 'Hueco muy profundo');
      expect(states.last.savedIncident?.categoryId, 2);
      expect(states.last.savedIncident?.trackingCode, '#VIG-1001');
    });

    test('a failed save (window over) keeps the form and shows the server message', () async {
      await open();
      bloc.add(const EditCategorySelected(2));
      picker.photoToReturn = _picked();
      bloc.add(const EditKeptPhotoRemoved('p2'));
      bloc.add(const EditPhotoPickRequested(fromCamera: false));
      await pumpEventQueue();
      repository.updateError = Exception(
        'Este reporte ya no se puede modificar ni eliminar: pasaron más de 30 minutos o tiene 5 apoyos o más.',
      );

      final states = await emittedStates(
        bloc,
        const EditSubmitted(title: 'Hueco muy profundo', description: 'Ahora ocupa todo el carril.'),
      );

      expect(states.last.status, EditReportStatus.ready);
      expect(states.last.errorMessage, contains('pasaron más de 30 minutos'));
      expect(states.last.categoryId, 2);
      expect(states.last.addedPhotos, hasLength(1));
      expect(states.last.keptPhotos.map((p) => p.id), ['p1']);
    });

    test('invalid text is refused before the repository is called', () async {
      await open();

      final states = await emittedStates(bloc, const EditSubmitted(title: 'Hey', description: 'Ahora ocupa todo el carril.'));

      expect(states.last.status, EditReportStatus.ready);
      expect(states.last.errorMessage, contains('al menos 5 caracteres'));
      expect(repository.calls, isNot(contains('incident.update')));
    });

    test('a guest cannot save', () async {
      bloc = buildEditBloc(repository, guest: true);
      await open();

      final states = await emittedStates(
        bloc,
        const EditSubmitted(title: 'Hueco muy profundo', description: 'Ahora ocupa todo el carril.'),
      );

      expect(states.last.errorMessage, contains('iniciar sesión'));
      expect(repository.calls, isNot(contains('incident.update')));
    });
  });
}

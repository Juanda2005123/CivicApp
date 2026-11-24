import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_photo.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:vigia_app/features/reports/ui/bloc/edit_report_bloc.dart';
import 'package:vigia_app/features/reports/ui/screens/edit_report_screen.dart';

import '../../support/edit_bloc_factory.dart';
import '../../support/fakes.dart';
import '../../support/incident_samples.dart';

IncidentPhoto _photo(String id) => IncidentPhoto(
      id: id,
      incidentId: 'inc-1',
      fileUrl: 'https://example.com/$id.jpg',
      uploadedAt: DateTime(2026, 11, 12),
    );

void main() {
  late FakeIncidentRepository repository;
  late FakePhotoPickerRepository picker;
  late Incident incident;
  bool? popped;

  setUp(() {
    popped = null;
    repository = FakeIncidentRepository();
    picker = FakePhotoPickerRepository();
    incident = sampleIncident(
      reporterId: 'me',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ).copyWith(photos: [_photo('p1')], estimatedDimensions: '1 m');
    repository.stored[incident.id] = incident;
  });

  /// The form is opened from a home with one button, so the pop result is visible.
  Future<EditReportBloc> openEdit(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final bloc = buildEditBloc(repository, picker: picker);
    addTearDown(bloc.close);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
                  builder: (_) => BlocProvider<EditReportBloc>.value(
                    value: bloc,
                    child: EditReportScreen(incident: incident),
                  ),
                ));
              },
              child: const Text('Abrir edición'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir edición'));
    await tester.pumpAndSettle();
    return bloc;
  }

  group('EditReportScreen (HU-18)', () {
    testWidgets('opens with the current values and says the code and place do not change', (tester) async {
      await openEdit(tester);

      expect(find.text('El código #VIG-1001 y la ubicación no se pueden cambiar.'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Hueco profundo en carril rápido'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Cráter de más de 20 cm de profundidad.'), findsOneWidget);
      expect(find.widgetWithText(TextField, '1 m'), findsOneWidget);
      expect(find.text('Fotos (1/3)'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);
    });

    testWidgets('saving a valid edit closes the form with true and the report keeps its code (criterion 2)',
        (tester) async {
      await openEdit(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Hueco profundo en carril rápido'), 'Hueco muy profundo');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      expect(repository.stored['inc-1']?.title, 'Hueco muy profundo');
      expect(repository.stored['inc-1']?.trackingCode, '#VIG-1001');
    });

    testWidgets('applies the publication rules: a short title is refused and nothing is saved', (tester) async {
      await openEdit(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Hueco profundo en carril rápido'), 'Hey');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text('El título debe tener al menos 5 caracteres.'), findsOneWidget);
      expect(repository.calls, isNot(contains('incident.update')));
      expect(popped, isNull);
    });

    testWidgets('when the window closed with the form open the server message shows and the text stays (criterion 5)',
        (tester) async {
      await openEdit(tester);
      repository.updateError = Exception(
        'Este reporte ya no se puede modificar ni eliminar: pasaron más de 30 minutos o tiene 5 apoyos o más.',
      );

      await tester.enterText(find.widgetWithText(TextField, 'Hueco profundo en carril rápido'), 'Hueco muy profundo');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.textContaining('pasaron más de 30 minutos'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Hueco muy profundo'), findsOneWidget, reason: 'the text is kept');
      expect(popped, isNull, reason: 'the form stays open');
    });

    testWidgets('removing a photo and adding another updates the count', (tester) async {
      await openEdit(tester);
      picker.photoToReturn = PickedPhoto(bytes: Uint8List(0), extension: 'jpg', sizeInBytes: 100);

      await tester.tap(find.byTooltip('Quitar foto'));
      await tester.pumpAndSettle();
      expect(find.text('Fotos (0/3)'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Agregar foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elegir foto de la galería'));
      await tester.pumpAndSettle();

      expect(find.text('Fotos (1/3)'), findsOneWidget);
    });

    testWidgets('a photo in a format that is not allowed is refused with the reason', (tester) async {
      await openEdit(tester);
      picker.photoToReturn = PickedPhoto(bytes: Uint8List(0), extension: 'gif', sizeInBytes: 100);

      await tester.tap(find.bySemanticsLabel('Agregar foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elegir foto de la galería'));
      await tester.pumpAndSettle();

      expect(find.textContaining('JPG, PNG o WebP'), findsOneWidget);
      expect(find.text('Fotos (1/3)'), findsOneWidget, reason: 'the photo it already had stays');
    });
  });
}

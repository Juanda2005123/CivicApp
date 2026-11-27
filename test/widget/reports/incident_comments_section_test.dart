import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_comment.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:vigia_app/features/reports/ui/bloc/comments_bloc.dart';
import 'package:vigia_app/features/reports/ui/widgets/incident_comments_section.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../support/comment_samples.dart';
import '../../support/detail_bloc_factory.dart';
import '../../support/fake_comment_repository.dart';
import '../../support/fakes.dart';

/// A real 1x1 PNG, so `Image.memory` can decode it.
final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  group('IncidentCommentsSection (HU-17)', () {
    late FakeCommentRepository repository;
    late FakePhotoPickerRepository picker;

    setUp(() {
      repository = FakeCommentRepository();
      picker = FakePhotoPickerRepository();
    });

    /// A tall screen so the whole thread and the composer are on screen.
    Future<CommentsBloc> pumpSection(
      WidgetTester tester, {
      List<IncidentComment> comments = const [],
      bool guest = false,
    }) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      repository.byIncident['inc-1'] = List.of(comments);
      final bloc = buildCommentsBloc(repository, guest: guest, picker: picker);
      addTearDown(bloc.close);

      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: BlocProvider<CommentsBloc>.value(
              value: bloc,
              child: const IncidentCommentsSection(incidentId: 'inc-1'),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return bloc;
    }

    ButtonStyleButton publishButton(WidgetTester tester) => tester.widget<ButtonStyleButton>(
          find.ancestor(of: find.text('Publicar'), matching: find.bySubtype<ButtonStyleButton>()),
        );

    String fieldText(WidgetTester tester) => tester.widget<TextField>(find.byType(TextField)).controller!.text;

    group('the thread', () {
      testWidgets('lists the comments oldest first with author, rank and date', (tester) async {
        await pumpSection(tester, comments: [
          sampleComment(id: 'c-1', text: 'Primero', authorId: 'other', createdAt: DateTime(2026, 11, 16, 10, 5)),
          sampleComment(id: 'c-2', text: 'Segundo', authorId: 'other', createdAt: DateTime(2026, 11, 16, 11, 30)),
        ]);

        expect(find.text('Comentarios (2)'), findsOneWidget);
        expect(find.text('Vecino Uno'), findsNWidgets(2));
        expect(find.text('Vecino Activo · 16/11/2026 10:05'), findsOneWidget);
        expect(find.text('Vecino Activo · 16/11/2026 11:30'), findsOneWidget);
        expect(tester.getTopLeft(find.text('Primero')).dy, lessThan(tester.getTopLeft(find.text('Segundo')).dy));
      });

      testWidgets('an empty thread invites to the first comment', (tester) async {
        await pumpSection(tester);

        expect(find.text('Comentarios (0)'), findsOneWidget);
        expect(find.textContaining('Aún no hay comentarios'), findsOneWidget);
      });

      testWidgets('a photo-only comment shows the photo and no text', (tester) async {
        await pumpSection(tester, comments: [
          sampleComment(authorId: 'other', text: '', photoUrl: 'https://example.com/p.jpg'),
        ]);

        // The network is not available in tests: the placeholder stands in for the photo.
        expect(find.byIcon(LucideIcons.imageOff), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a failed load shows the error and "Reintentar" loads it', (tester) async {
        repository.getError = Exception('Sin conexión');
        await pumpSection(tester);
        expect(find.text('Sin conexión'), findsOneWidget);

        repository.getError = null;
        repository.byIncident['inc-1'] = [sampleComment(text: 'Ya cargó', authorId: 'other')];
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();

        expect(find.text('Ya cargó'), findsOneWidget);
        expect(find.text('Reintentar'), findsNothing);
      });
    });

    group('writing a comment', () {
      testWidgets('"Publicar" is disabled until there is text or a photo', (tester) async {
        await pumpSection(tester);
        expect(publishButton(tester).onPressed, isNull);

        await tester.enterText(find.byType(TextField), 'Hola');
        await tester.pump();
        expect(publishButton(tester).onPressed, isNotNull);

        await tester.enterText(find.byType(TextField), '   ');
        await tester.pump();
        expect(publishButton(tester).onPressed, isNull);
      });

      testWidgets('publishing adds the comment and empties the field', (tester) async {
        await pumpSection(tester);

        await tester.enterText(find.byType(TextField), 'Hola vecinos');
        await tester.pump();
        await tester.tap(find.text('Publicar'));
        await tester.pumpAndSettle();

        expect(find.text('Comentarios (1)'), findsOneWidget);
        expect(find.text('Hola vecinos'), findsOneWidget);
        expect(fieldText(tester), isEmpty);
        expect(repository.lastText, 'Hola vecinos');
      });

      testWidgets('a failed publish keeps the text and shows why (criterion 7)', (tester) async {
        await pumpSection(tester);
        repository.addError = Exception('Sin conexión');

        await tester.enterText(find.byType(TextField), 'Hola vecinos');
        await tester.pump();
        await tester.tap(find.text('Publicar'));
        await tester.pumpAndSettle();

        expect(find.text('Sin conexión'), findsOneWidget);
        expect(fieldText(tester), 'Hola vecinos');
        expect(find.text('Comentarios (0)'), findsOneWidget);
      });

      testWidgets('a photo can be attached, removed and published alone', (tester) async {
        picker.photoToReturn = PickedPhoto(bytes: _pixel, extension: 'png', sizeInBytes: _pixel.length);
        await pumpSection(tester);

        await tester.tap(find.byTooltip('Elegir una foto de la galería'));
        await tester.pumpAndSettle();
        expect(find.text('Foto adjunta'), findsOneWidget);
        expect(publishButton(tester).onPressed, isNotNull, reason: 'a photo alone is enough');

        await tester.tap(find.byTooltip('Quitar la foto'));
        await tester.pumpAndSettle();
        expect(find.text('Foto adjunta'), findsNothing);

        await tester.tap(find.byTooltip('Tomar una foto'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Publicar'));
        await tester.pumpAndSettle();

        expect(find.text('Comentarios (1)'), findsOneWidget);
        expect(find.text('Foto adjunta'), findsNothing);
        expect(repository.lastPhoto, isNotNull);
      });

      testWidgets('a photo in the wrong format is refused with the reason', (tester) async {
        picker.photoToReturn = PickedPhoto(bytes: _pixel, extension: 'gif', sizeInBytes: _pixel.length);
        await pumpSection(tester);

        await tester.tap(find.byTooltip('Elegir una foto de la galería'));
        await tester.pumpAndSettle();

        expect(find.textContaining('JPG, PNG o WebP'), findsOneWidget);
        expect(find.text('Foto adjunta'), findsNothing);
      });

      testWidgets('tells the citizen what a comment gives and its deletion window', (tester) async {
        await pumpSection(tester);

        expect(find.textContaining('+15 XP'), findsOneWidget);
        expect(find.textContaining('primeros 5 minutos'), findsOneWidget);
      });
    });

    group('deleting', () {
      testWidgets('only the own comment inside the window has "Eliminar"', (tester) async {
        await pumpSection(tester, comments: [
          sampleComment(id: 'c-1', text: 'Mío reciente', createdAt: DateTime.now()),
          sampleComment(id: 'c-2', text: 'Mío viejo', createdAt: DateTime.now().subtract(const Duration(hours: 1))),
          sampleComment(id: 'c-3', text: 'De otro', authorId: 'other', createdAt: DateTime.now()),
        ]);

        expect(find.text('Eliminar'), findsOneWidget);
      });

      testWidgets('confirming deletes the comment', (tester) async {
        await pumpSection(tester, comments: [sampleComment(text: 'Mío reciente', createdAt: DateTime.now())]);

        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();
        expect(find.text('¿Eliminar tu comentario?'), findsOneWidget);
        expect(find.textContaining('15 XP'), findsWidgets);

        await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Eliminar')));
        await tester.pumpAndSettle();

        expect(find.text('Mío reciente'), findsNothing);
        expect(find.text('Comentarios (0)'), findsOneWidget);
        expect(repository.calls, contains('comment.delete'));
      });

      testWidgets('cancelling keeps the comment', (tester) async {
        await pumpSection(tester, comments: [sampleComment(text: 'Mío reciente', createdAt: DateTime.now())]);

        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();

        expect(find.text('Mío reciente'), findsOneWidget);
        expect(repository.calls, isNot(contains('comment.delete')));
      });
    });

    group('a guest (HU-22)', () {
      testWidgets('reads the thread and is asked to sign in to write', (tester) async {
        await pumpSection(tester, guest: true, comments: [sampleComment(text: 'Visible', authorId: 'other')]);

        expect(find.text('Visible'), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Eliminar'), findsNothing);

        await tester.tap(find.text('Inicia sesión para comentar'));
        await tester.pumpAndSettle();

        expect(find.text('Necesitas iniciar sesión'), findsOneWidget);
        expect(find.textContaining('Para comentar necesitas una cuenta'), findsOneWidget);
        expect(repository.calls, isNot(contains('comment.add')));
      });
    });
  });
}

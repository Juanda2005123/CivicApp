import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/widgets/dotted_spinner.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_photo.dart';

import 'package:vigia_app/features/reports/ui/bloc/incident_detail_bloc.dart';
import 'package:vigia_app/features/reports/ui/screens/incident_detail_screen.dart';

import '../../support/detail_bloc_factory.dart';
import '../../support/fakes.dart';

void main() {
  group('IncidentDetailScreen Widget Tests', () {
    late FakeIncidentRepository repository;

    final sampleIncident = Incident(
      id: 'inc-1001',
      trackingCode: '#VIG-1001',
      reporterId: 'user-99',
      reporterName: 'Carlos Ciudadano',
      reporterRankName: 'Guardián Vial',
      categoryId: 1,
      categoryName: 'Hueco',
      title: 'Hueco profundo en carril rápido',
      description: 'Cráter de más de 20cm de profundidad que puede reventar llantas.',
      severity: IncidentSeverity.high,
      status: IncidentStatus.reported,
      estimatedDimensions: '1.2m x 0.8m, prof: 20cm',
      coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
      formattedAddress: 'Calle 5 con Carrera 44',
      neighborhood: 'Tequendama',
      city: 'Cali',
      photos: [
        IncidentPhoto(
          id: 'photo-1',
          incidentId: 'inc-1001',
          fileUrl: 'https://images.example.com/p1.jpg',
          isPrimary: true,
          uploadedAt: DateTime(2026, 11, 12),
        ),
      ],
      upvotesCount: 4,
      createdAt: DateTime(2026, 11, 12),
    );

    setUp(() {
      repository = FakeIncidentRepository();
    });

    IncidentDetailBloc newBloc() {
      final bloc = buildDetailBloc(repository);
      addTearDown(bloc.close);
      return bloc;
    }

    Widget createWidgetUnderTest(IncidentDetailBloc bloc, {String? incidentIdOrCode}) {
      return MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<IncidentDetailBloc>.value(
          value: bloc,
          child: IncidentDetailScreen(incidentIdOrCode: incidentIdOrCode),
        ),
      );
    }

    testWidgets('renders loading spinner and loads report on start', (tester) async {
      repository.stored['#VIG-1001'] = sampleIncident;
      final bloc = newBloc();

      await tester.pumpWidget(createWidgetUnderTest(bloc, incidentIdOrCode: '#VIG-1001'));
      // Initially loading
      await tester.pump();
      expect(find.text('Detalle del reporte'), findsOneWidget);

      await tester.pumpAndSettle();

      // Successfully loaded
      expect(find.text('#VIG-1001'), findsOneWidget);
      expect(find.text('Hueco profundo en carril rápido'), findsOneWidget);
    });

    testWidgets('while the report loads it shows the spinner, never the error view', (tester) async {
      final pending = Completer<Incident>();
      final bloc = buildDetailBloc(_SlowIncidentRepository(pending.future));
      addTearDown(bloc.close);

      await tester.pumpWidget(createWidgetUnderTest(bloc, incidentIdOrCode: '#VIG-1001'));
      await tester.pump();

      expect(find.byType(DottedSpinner), findsOneWidget);
      expect(find.text('No fue posible cargar el reporte vial.'), findsNothing);
      expect(find.text('Reintentar'), findsNothing);

      pending.complete(sampleIncident);
      await tester.pumpAndSettle();

      expect(find.text('Hueco profundo en carril rápido'), findsOneWidget);
    });

    testWidgets('renders all incident details correctly on success', (tester) async {
      repository.stored['#VIG-1001'] = sampleIncident;
      final bloc = newBloc();

      await tester.pumpWidget(createWidgetUnderTest(bloc, incidentIdOrCode: '#VIG-1001'));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('#VIG-1001'), findsOneWidget);
      expect(find.text('Reportado'), findsOneWidget);
      expect(find.text('Alta'), findsOneWidget);
      expect(find.text('· Hueco'), findsOneWidget);

      // Validation progress
      expect(find.text('Validación comunitaria'), findsOneWidget);
      expect(find.text('4 de 10 apoyos'), findsOneWidget);

      // Problem description & dimensions
      expect(find.text('Hueco profundo en carril rápido'), findsOneWidget);
      expect(find.text('Cráter de más de 20cm de profundidad que puede reventar llantas.'), findsOneWidget);
      expect(find.text('Dimensiones estimadas: 1.2m x 0.8m, prof: 20cm'), findsOneWidget);

      // Georeferenced location
      expect(find.text('Ubicación georreferenciada'), findsOneWidget);
      expect(find.text('Calle 5 con Carrera 44, Tequendama'), findsOneWidget);
      expect(find.text('Cali'), findsOneWidget);
      expect(find.text('3.45160°, -76.53200°'), findsOneWidget);

      // Author identity (excluding any email address)
      expect(find.text('Carlos Ciudadano'), findsOneWidget);
      expect(find.textContaining('Guardián Vial'), findsOneWidget);
      expect(find.textContaining('@'), findsNothing); // Never leaks email
    });

    testWidgets('renders fallback placeholder when incident has no photos', (tester) async {
      final noPhotosIncident = Incident(
        id: 'inc-1002',
        trackingCode: '#VIG-1002',
        reporterId: 'user-1',
        categoryId: 1,
        title: 'Bache en calzada',
        description: 'Bache reportado sin fotografía adjunta.',
        severity: IncidentSeverity.low,
        coordinates: const Coordinates(latitude: 3.45, longitude: -76.53),
        formattedAddress: 'Avenida 6N',
        neighborhood: 'Granada',
        city: 'Cali',
        photos: const [],
        createdAt: DateTime(2026, 11, 12),
      );
      repository.stored['#VIG-1002'] = noPhotosIncident;

      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc, incidentIdOrCode: '#VIG-1002'));
      await tester.pumpAndSettle();

      expect(find.text('Sin fotografías adjuntas'), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('renders error notice and retry button when report does not exist', (tester) async {
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc, incidentIdOrCode: '#NON-EXISTENT'));
      await tester.pumpAndSettle();

      expect(find.text('Reporte no encontrado'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}

/// Answers only when the test completes [_answer], so the loading state stays
/// on screen long enough to be checked.
class _SlowIncidentRepository extends FakeIncidentRepository {
  final Future<Incident> _answer;

  _SlowIncidentRepository(this._answer);

  @override
  Future<Incident> getIncidentById(String idOrTrackingCode) => _answer;
}

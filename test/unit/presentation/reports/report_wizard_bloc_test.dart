import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_category.dart';
import 'package:vigia_app/features/reports/domain/entities/nearby_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:vigia_app/features/reports/domain/usecases/create_incident_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/endorse_incident_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_categories_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_nearby_incidents_usecase.dart';
import 'package:vigia_app/features/reports/ui/bloc/report_wizard_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/report_wizard_event.dart';
import 'package:vigia_app/features/reports/ui/bloc/report_wizard_state.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/fakes.dart';

void main() {
  group('ReportWizardBloc Tests', () {
    late FakeCategoryRepository fakeCategoryRepo;
    late FakeIncidentRepository fakeIncidentRepo;
    late ReportWizardBloc bloc;

    setUp(() {
      fakeCategoryRepo = FakeCategoryRepository(categories: [
        const IncidentCategory(id: 1, name: 'Hueco', icon: 'pothole'),
        const IncidentCategory(id: 2, name: 'Semáforo', icon: 'traffic_light'),
      ]);
      fakeIncidentRepo = FakeIncidentRepository();

      bloc = ReportWizardBloc(
        getCategories: GetCategoriesUseCase(fakeCategoryRepo),
        getNearbyIncidents: GetNearbyIncidentsUseCase(fakeIncidentRepo),
        createIncident: CreateIncidentUseCase(fakeIncidentRepo),
        endorseIncident: EndorseIncidentUseCase(fakeIncidentRepo),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('WizardStarted loads categories and transitions to ready', () async {
      final states = await emittedStates(bloc, WizardStarted());

      expect(states.map((s) => s.status), [
        WizardStatus.loading,
        WizardStatus.ready,
      ]);
      expect(states.last.categories.length, 2);
    });

    test('LocationPitched sets coordinates and advances to Step 2', () async {
      final states = await emittedStates(
        bloc,
        const LocationPitched(
          coordinates: Coordinates(latitude: 3.4516, longitude: -76.5320),
          formattedAddress: 'Calle 5 # 38-00',
          neighborhood: 'San Fernando',
          city: 'Cali',
        ),
      );

      expect(states.length, 1);
      expect(states.first.currentStep, 2);
      expect(states.first.formattedAddress, 'Calle 5 # 38-00');
      expect(states.first.hasDraftData, true);
    });

    test('CategoryAndSeveritySelected advances to Step 3 when no nearby reports', () async {
      // Setup step 1 location first
      bloc.add(const LocationPitched(
        coordinates: Coordinates(latitude: 3.4516, longitude: -76.5320),
        formattedAddress: 'Calle 5',
        neighborhood: 'San Fernando',
        city: 'Cali',
      ));
      await pumpEventQueue();

      final states = await emittedStates(
        bloc,
        const CategoryAndSeveritySelected(
          categoryId: 1,
          severity: IncidentSeverity.high,
        ),
      );

      expect(states.last.currentStep, 3);
      expect(states.last.selectedCategoryId, 1);
      expect(states.last.severity, IncidentSeverity.high);
    });

    test('CategoryAndSeveritySelected stays on Step 2 when nearby reports are detected', () async {
      fakeIncidentRepo.nearbyToReturn = [
        const NearbyIncident(
          id: 'inc-99',
          trackingCode: '#VIG-9999',
          title: 'Hueco peligroso',
          categoryId: 1,
          categoryName: 'Hueco',
          severity: 'HIGH',
          distanceInMeters: 40.0,
        ),
      ];

      bloc.add(const LocationPitched(
        coordinates: Coordinates(latitude: 3.4516, longitude: -76.5320),
        formattedAddress: 'Calle 5',
        neighborhood: 'San Fernando',
        city: 'Cali',
      ));
      await pumpEventQueue();

      final states = await emittedStates(
        bloc,
        const CategoryAndSeveritySelected(
          categoryId: 1,
          severity: IncidentSeverity.high,
        ),
      );

      expect(states.last.currentStep, 2);
      expect(states.last.nearbyIncidents.length, 1);
    });

    test('NearbyReportEndorsed endorses existing report and marks isEndorsedNearby true', () async {
      final states = await emittedStates(
        bloc,
        const NearbyReportEndorsed(incidentId: 'inc-99', userId: 'user-123'),
      );

      expect(states.map((s) => s.status), [
        WizardStatus.submitting,
        WizardStatus.success,
      ]);
      expect(states.last.isEndorsedNearby, true);
      expect(fakeIncidentRepo.calls, contains('incident.endorse'));
    });

    test('Full wizard flow from Step 1 to Step 5 submits successfully', () async {
      // Step 1: Location
      bloc.add(const LocationPitched(
        coordinates: Coordinates(latitude: 3.4516, longitude: -76.5320),
        formattedAddress: 'Calle 5 # 38-00',
        neighborhood: 'San Fernando',
        city: 'Cali',
      ));
      await pumpEventQueue();

      // Step 2: Category & Severity
      bloc.add(const CategoryAndSeveritySelected(
        categoryId: 1,
        severity: IncidentSeverity.high,
      ));
      await pumpEventQueue();

      // Step 3: Photos
      final testPhoto = PickedPhoto(
        bytes: Uint8List(100),
        extension: 'jpg',
        sizeInBytes: 1024,
      );
      bloc.add(PhotosUpdated([testPhoto]));
      await pumpEventQueue();

      // Step 4: Details
      bloc.add(const DetailsSubmitted(
        title: 'Bache enorme en la avenida',
        description: 'Bache profundo frente al supermercado con riesgo de choque.',
        dimensions: '~2m x 20cm',
      ));
      await pumpEventQueue();

      expect(bloc.state.currentStep, 5);

      // Step 5: Submit confirmed
      final submitStates = await emittedStates(
        bloc,
        const ReportSubmitConfirmed('user-123'),
      );

      expect(submitStates.map((s) => s.status), [
        WizardStatus.submitting,
        WizardStatus.success,
      ]);
      expect(submitStates.last.publishedIncident?.title, 'Bache enorme en la avenida');
      expect(submitStates.last.publishedIncident?.trackingCode, startsWith('#VIG-'));
    });
  });
}

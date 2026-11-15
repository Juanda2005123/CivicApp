import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/usecases/detect_nearest_city_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/open_location_settings_usecase.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_category.dart';
import 'package:vigia_app/features/reports/domain/entities/nearby_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:vigia_app/features/reports/domain/usecases/create_incident_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/endorse_incident_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_categories_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_current_location_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_nearby_incidents_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/pick_photo_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/suggest_address_usecase.dart';
import 'package:vigia_app/features/reports/domain/entities/geocoded_place.dart';
import 'package:vigia_app/features/reports/domain/entities/suggested_address.dart';
import 'package:vigia_app/features/reports/ui/bloc/report_wizard_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/report_wizard_event.dart';
import 'package:vigia_app/features/reports/ui/bloc/report_wizard_state.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/fakes.dart';

void main() {
  group('ReportWizardBloc Tests', () {
    late FakeCategoryRepository fakeCategoryRepo;
    late FakeIncidentRepository fakeIncidentRepo;
    late FakeAuthRepository fakeAuthRepo;
    late FakeProfileRepository fakeProfileRepo;
    late FakeLocationRepository fakeLocationRepo;
    late FakeCityRepository fakeCityRepo;
    late FakePhotoPickerRepository fakePhotoPickerRepo;
    late FakeGeocodingRepository fakeGeocodingRepo;
    late ReportWizardBloc bloc;

    setUp(() {
      fakeCategoryRepo = FakeCategoryRepository(categories: [
        const IncidentCategory(id: 1, name: 'Hueco', icon: 'pothole'),
        const IncidentCategory(id: 2, name: 'Semáforo', icon: 'traffic_light'),
      ]);
      fakeIncidentRepo = FakeIncidentRepository();
      fakeAuthRepo = FakeAuthRepository(
        user: const AuthUser(id: 'user-123', email: 'user@example.com'),
      );
      fakeProfileRepo = FakeProfileRepository();
      fakeProfileRepo.stored['user-123'] = const Profile(
        id: 'user-123',
        email: 'user@example.com',
        fullName: 'Juan Quintero',
        cityName: 'Popayán',
      );
      fakeLocationRepo = FakeLocationRepository(
        coordinates: const Coordinates(latitude: 2.4448, longitude: -76.6147),
      );
      fakeCityRepo = FakeCityRepository([
        const City(id: 19, name: 'Popayán', department: 'Cauca', latitude: 2.4448, longitude: -76.6147, isCapital: true),
        const City(id: 1, name: 'Cali', department: 'Valle del Cauca', latitude: 3.4516, longitude: -76.5320, isCapital: true),
      ]);
      fakePhotoPickerRepo = FakePhotoPickerRepository();
      fakeGeocodingRepo = FakeGeocodingRepository();

      bloc = ReportWizardBloc(
        GetCategoriesUseCase(fakeCategoryRepo),
        GetNearbyIncidentsUseCase(fakeIncidentRepo),
        CreateIncidentUseCase(fakeIncidentRepo),
        EndorseIncidentUseCase(fakeIncidentRepo),
        GetCurrentProfileUseCase(fakeAuthRepo, fakeProfileRepo),
        GetCurrentLocationUseCase(fakeLocationRepo),
        PickPhotoUseCase(fakePhotoPickerRepo),
        DetectNearestCityUseCase(fakeLocationRepo, fakeCityRepo),
        OpenLocationSettingsUseCase(fakeLocationRepo),
        SuggestAddressUseCase(fakeGeocodingRepo),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('WizardStarted loads categories and detects current Popayán coordinates', () async {
      final states = await emittedStates(bloc, WizardStarted());

      expect(states.map((s) => s.status).toSet().toList(), [
        WizardStatus.loading,
        WizardStatus.ready,
      ]);
      expect(states.last.categories.length, 2);
      expect(states.last.coordinates?.latitude, 2.4448);
      expect(states.last.coordinates?.longitude, -76.6147);
      expect(states.last.city, 'Popayán');
    });

    test('WizardStarted suggests the address of the GPS position without opening the map (HU-26)', () async {
      fakeGeocodingRepo.place = const GeocodedPlace(road: 'Calle 12', houseNumber: '5-37', neighborhood: 'San Pedro');

      final states = await emittedStates(bloc, WizardStarted());

      expect(states.any((s) => s.isSuggestingAddress), true);
      expect(states.last.isSuggestingAddress, false);
      expect(
        states.last.suggestedAddress,
        const SuggestedAddress(roadType: 'Calle', mainRoad: '12', crossRoad: '5', plot: '37', neighborhood: 'San Pedro'),
      );
    });

    test('WizardStarted without a GPS position suggests nothing', () async {
      bloc = ReportWizardBloc(
        GetCategoriesUseCase(fakeCategoryRepo),
        GetNearbyIncidentsUseCase(fakeIncidentRepo),
        CreateIncidentUseCase(fakeIncidentRepo),
        EndorseIncidentUseCase(fakeIncidentRepo),
        GetCurrentProfileUseCase(fakeAuthRepo, fakeProfileRepo),
        GetCurrentLocationUseCase(FakeLocationRepository(error: Exception('Sin señal de GPS.'))),
        PickPhotoUseCase(fakePhotoPickerRepo),
        DetectNearestCityUseCase(fakeLocationRepo, fakeCityRepo),
        OpenLocationSettingsUseCase(fakeLocationRepo),
        SuggestAddressUseCase(fakeGeocodingRepo),
      );

      final states = await emittedStates(bloc, WizardStarted());

      expect(fakeGeocodingRepo.calls, 0);
      expect(states.any((s) => s.isSuggestingAddress), false);
      expect(states.last.addressSuggestionMessage, isNull);
    });

    test('CurrentLocationRequested updates coordinates and city with feedback', () async {
      final states = await emittedStates(bloc, CurrentLocationRequested());

      expect(states.last.isLocating, false);
      expect(states.last.coordinates?.latitude, 2.4448);
      expect(states.last.locationStatusMessage, contains('GPS detectado'));
      expect(states.last.isLocationBlocked, false);
    });

    test('CurrentLocationRequested suggests the address from the GPS (HU-26)', () async {
      fakeGeocodingRepo.place = const GeocodedPlace(road: 'Calle 12', houseNumber: '5-37', neighborhood: 'San Pedro');

      final states = await emittedStates(bloc, CurrentLocationRequested());

      expect(fakeGeocodingRepo.calls, 1);
      expect(
        states.last.suggestedAddress,
        const SuggestedAddress(roadType: 'Calle', mainRoad: '12', crossRoad: '5', plot: '37', neighborhood: 'San Pedro'),
      );
      expect(states.last.coordinates?.latitude, 2.4448);
    });

    test('the address arrives first and the cross street later, flagged as loading meanwhile', () async {
      fakeGeocodingRepo
        ..place = const GeocodedPlace(
          road: 'Calle 10A Bis',
          roadPath: [Coordinates(latitude: 2.4448, longitude: -76.6150), Coordinates(latitude: 2.4448, longitude: -76.6140)],
        )
        ..streetAnswers = const [GeocodedPlace(road: 'Carrera 67A')];

      final states = await emittedStates(bloc, CurrentLocationRequested());

      final suggesting = states.where((s) => s.isSuggestingAddress).toList();
      expect(suggesting.first.suggestedAddress, isNull);
      expect(suggesting.map((s) => s.suggestedAddress?.crossRoad), containsAllInOrder([null, '67A']));
      expect(suggesting.any((s) => s.suggestedAddress?.mainRoad == '10A Bis' && s.suggestedAddress?.crossRoad == null), true);
      expect(states.last.isSuggestingAddress, false);
      expect(states.last.suggestedAddress?.crossRoad, '67A');
      expect(states.last.addressSuggestionMessage, isNull);
    });

    test('an address without a cross street or without a known road says what is missing', () async {
      fakeGeocodingRepo.place = const GeocodedPlace(road: 'Calle 12');
      var states = await emittedStates(bloc, CurrentLocationRequested());
      expect(states.last.addressSuggestionMessage, 'No encontramos el cruce. Escríbelo a mano.');

      fakeGeocodingRepo.place = const GeocodedPlace(road: 'Vía al Mar', neighborhood: 'Dapa');
      states = await emittedStates(bloc, CurrentLocationRequested());
      expect(states.first.addressSuggestionMessage, isNull);
      expect(states.last.addressSuggestionMessage, 'No reconocimos la vía en este punto. Escribe la dirección a mano.');
    });

    test('a failing address suggestion says why and keeps the GPS result', () async {
      fakeGeocodingRepo.error = Exception('La sugerencia de dirección tardó demasiado.');

      final states = await emittedStates(bloc, CurrentLocationRequested());

      expect(states.last.suggestedAddress, isNull);
      expect(states.last.isSuggestingAddress, false);
      expect(states.last.addressSuggestionMessage, 'La sugerencia de dirección tardó demasiado. Escríbela a mano.');
      expect(states.last.coordinates?.latitude, 2.4448);
      expect(states.last.locationStatusMessage, contains('GPS detectado'));
      expect(states.last.errorMessage, isNull);
    });

    test('every GPS reading clears the previous suggestion first', () async {
      fakeGeocodingRepo.place = const GeocodedPlace(road: 'Calle 12');
      await emittedStates(bloc, CurrentLocationRequested());

      final states = await emittedStates(bloc, CurrentLocationRequested());

      expect(states.first.suggestedAddress, isNull);
      expect(states.last.suggestedAddress?.mainRoad, '12');
    });

    test('MapPointSelected takes the picked point, its city and its address (HU-27)', () async {
      fakeGeocodingRepo.place = const GeocodedPlace(road: 'Calle 12', houseNumber: '5-37', neighborhood: 'San Pedro');
      const picked = Coordinates(latitude: 3.4520, longitude: -76.5330);

      final states = await emittedStates(bloc, const MapPointSelected(picked));

      expect(states.first.suggestedAddress, isNull);
      expect(states.last.coordinates, picked);
      expect(states.last.city, 'Cali');
      expect(states.last.suggestedAddress?.mainRoad, '12');
      expect(states.last.isSuggestingAddress, false);
    });

    test('CurrentLocationRequested flags a blocked permission', () async {
      bloc = ReportWizardBloc(
        GetCategoriesUseCase(fakeCategoryRepo),
        GetNearbyIncidentsUseCase(fakeIncidentRepo),
        CreateIncidentUseCase(fakeIncidentRepo),
        EndorseIncidentUseCase(fakeIncidentRepo),
        GetCurrentProfileUseCase(fakeAuthRepo, fakeProfileRepo),
        GetCurrentLocationUseCase(
          FakeLocationRepository(error: Exception(LocationRepository.blockedMessage)),
        ),
        PickPhotoUseCase(fakePhotoPickerRepo),
        DetectNearestCityUseCase(fakeLocationRepo, fakeCityRepo),
        OpenLocationSettingsUseCase(fakeLocationRepo),
        SuggestAddressUseCase(fakeGeocodingRepo),
      );

      final states = await emittedStates(bloc, CurrentLocationRequested());

      expect(states.last.isLocationBlocked, true);
      expect(states.last.locationStatusMessage, LocationRepository.blockedMessage);
    });

    test('LocationSettingsRequested opens the system settings', () async {
      await emittedStates(bloc, LocationSettingsRequested());

      expect(fakeLocationRepo.openSettingsCalls, 1);
    });

    test('PhotoPickRequested appends selected photo to state', () async {
      final testPhoto = PickedPhoto(
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
        extension: 'jpg',
        sizeInBytes: 1024,
      );
      fakePhotoPickerRepo.photoToReturn = testPhoto;

      final states = await emittedStates(
        bloc,
        const PhotoPickRequested(fromCamera: false),
      );

      expect(states.last.photos.length, 1);
      expect(states.last.photos.first.extension, 'jpg');
    });

    test('PhotoRemoved deletes photo at given index', () async {
      final photo1 = PickedPhoto(bytes: Uint8List(10), extension: 'jpg', sizeInBytes: 10);
      final photo2 = PickedPhoto(bytes: Uint8List(20), extension: 'png', sizeInBytes: 20);
      bloc.add(PhotosUpdated([photo1, photo2]));
      await pumpEventQueue();

      final states = await emittedStates(bloc, const PhotoRemoved(0));

      expect(states.last.photos.length, 1);
      expect(states.last.photos.first.extension, 'png');
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
      bloc.add(const LocationPitched(
        coordinates: Coordinates(latitude: 3.4516, longitude: -76.5320),
        formattedAddress: 'Calle 5 # 10 - 20',
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
        formattedAddress: 'Calle 5 # 10 - 20',
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
        const NearbyReportEndorsed('inc-99'),
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
        ReportSubmitConfirmed(),
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

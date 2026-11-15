import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/detect_nearest_city_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/open_location_settings_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_category.dart';
import 'package:vigia_app/features/reports/domain/usecases/create_incident_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/endorse_incident_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_categories_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_current_location_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_nearby_incidents_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/pick_photo_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/suggest_address_usecase.dart';
import 'package:vigia_app/features/reports/domain/entities/geocoded_place.dart';
import 'package:vigia_app/features/reports/ui/bloc/report_wizard_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/report_wizard_event.dart';
import 'package:vigia_app/features/reports/ui/screens/report_wizard_screen.dart';

import '../../support/fakes.dart';

void main() {
  group('ReportWizardScreen Widget Tests', () {
    late FakeCategoryRepository fakeCategoryRepo;
    late FakeIncidentRepository fakeIncidentRepo;
    late FakeAuthRepository fakeAuthRepo;
    late FakeProfileRepository fakeProfileRepo;
    late FakeLocationRepository fakeLocationRepo;
    late FakeCityRepository fakeCityRepo;
    late FakePhotoPickerRepository fakePhotoPickerRepo;
    late FakeGeocodingRepository fakeGeocodingRepo;

    setUp(() {
      fakeCategoryRepo = FakeCategoryRepository(categories: [
        const IncidentCategory(id: 1, name: 'Hueco', icon: 'pothole'),
        const IncidentCategory(id: 2, name: 'Semáforo', icon: 'traffic_light'),
      ]);
      fakeIncidentRepo = FakeIncidentRepository();
      fakeAuthRepo = FakeAuthRepository(user: const AuthUser(id: 'u-1', email: 'u@test.com'));
      fakeProfileRepo = FakeProfileRepository();
      fakeProfileRepo.stored['u-1'] = const Profile(
        id: 'u-1',
        email: 'u@test.com',
        fullName: 'Citizen One',
        cityName: 'Cali',
      );
      fakeLocationRepo = FakeLocationRepository(
        coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
      );
      fakeCityRepo = FakeCityRepository([
        const City(id: 1, name: 'Cali', department: 'Valle del Cauca', latitude: 3.4516, longitude: -76.5320, isCapital: true),
      ]);
      fakePhotoPickerRepo = FakePhotoPickerRepository();
      fakeGeocodingRepo = FakeGeocodingRepository();
    });

    ReportWizardBloc newBloc() {
      final bloc = ReportWizardBloc(
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
      )..add(WizardStarted());
      addTearDown(bloc.close);
      return bloc;
    }

    Widget createWidgetUnderTest(ReportWizardBloc bloc) {
      return MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<ReportWizardBloc>.value(
          value: bloc,
          child: const ReportWizardScreen(),
        ),
      );
    }

    /// Opens the Step 1 map, reads the GPS from it and goes back to the form.
    Future<void> useMyLocationOnMap(WidgetTester tester) async {
      await tester.tap(find.text('Seleccionar ubicación'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Centrar en mi ubicación'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Volver'));
      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
    }

    testWidgets('"Seleccionar ubicación" opens the map inside Step 1 and "Confirmar punto" fills the address (HU-27)', (tester) async {
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pumpAndSettle();
      fakeGeocodingRepo.place = const GeocodedPlace(road: 'Calle 12', houseNumber: '5-37', neighborhood: 'San Pedro');

      await tester.tap(find.text('Seleccionar ubicación'));
      await tester.pumpAndSettle();

      expect(find.text('Paso 1 de 5'), findsOneWidget);
      expect(find.text('Selecciona el punto en el mapa'), findsOneWidget);
      expect(find.bySemanticsLabel('Punto del daño'), findsOneWidget);

      await tester.ensureVisible(find.text('Confirmar punto'));
      await tester.tap(find.text('Confirmar punto'));
      await tester.pumpAndSettle();

      expect(find.text('Paso 1 de 5'), findsOneWidget);
      expect(find.text('Confirmar ubicación'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('San Pedro'), findsOneWidget);
      expect(bloc.state.coordinates?.latitude, closeTo(3.4516, 1e-6));
    });

    testWidgets('on a tall screen the Step 1 map fills the space below the header (HU-27)', (tester) async {
      tester.view.physicalSize = const Size(480, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seleccionar ubicación'));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(FlutterMap)).height, greaterThan(AppSizes.mapPicker));
      expect(find.text('Paso 1 de 5'), findsOneWidget);
      expect(tester.getBottomLeft(find.text('Volver')).dy, lessThanOrEqualTo(900));
    });

    testWidgets('renders Step 1 with GPS coordinates, nomenclature fields, and confirm action', (tester) async {
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pumpAndSettle();

      expect(find.text('Paso 1 de 5'), findsOneWidget);
      expect(find.text('Ubica el daño en la vía'), findsOneWidget);
      expect(find.text('Confirmar ubicación'), findsOneWidget);
      expect(find.text('Nomenclatura vial'), findsOneWidget);
      expect(find.text('Punto de referencia'), findsOneWidget);
      expect(find.text('Barrio o sector'), findsOneWidget);
      expect(find.text('Seleccionar ubicación'), findsOneWidget);
    });

    testWidgets('the GPS on the map fills the nomenclature and neighborhood, all still editable (HU-26)', (tester) async {
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pumpAndSettle();
      fakeGeocodingRepo.place = const GeocodedPlace(road: 'Calle 12', houseNumber: '5-37', neighborhood: 'San Pedro');

      // Something typed before the tap is overwritten by the suggestion.
      await tester.enterText(find.byType(TextField).at(3), 'Centro');
      await useMyLocationOnMap(tester);

      expect(find.text('Calle'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('37'), findsOneWidget);
      expect(find.text('San Pedro'), findsOneWidget);
      expect(find.text('Centro'), findsNothing);
      expect(find.textContaining('Sugerimos la dirección de este punto'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '13');
      await tester.pump();
      expect(find.text('13'), findsOneWidget);
    });

    testWidgets('opening the wizard fills the address from the GPS without opening the map (HU-26)', (tester) async {
      fakeGeocodingRepo.place = const GeocodedPlace(road: 'Calle 12', houseNumber: '5-37', neighborhood: 'San Pedro');
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pumpAndSettle();

      expect(find.text('Calle'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('San Pedro'), findsOneWidget);
    });

    testWidgets('without a plate, the GPS takes the cross street from a nearby corner', (tester) async {
      // The GPS gives (3.4516, -76.5320), on the street's line: the first
      // probe beside it answers Carrera 67A.
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pumpAndSettle();
      fakeGeocodingRepo
        ..place = const GeocodedPlace(
          road: 'Calle 10A Bis',
          roadPath: [Coordinates(latitude: 3.4516, longitude: -76.5322), Coordinates(latitude: 3.4516, longitude: -76.5300)],
        )
        ..streetAnswers = const [GeocodedPlace(road: 'Carrera 67A')];

      await useMyLocationOnMap(tester);

      expect(find.text('10A Bis'), findsOneWidget);
      expect(find.text('67A'), findsOneWidget);
    });

    testWidgets('the GPS with a blocked permission opens the settings modal', (tester) async {
      fakeLocationRepo = FakeLocationRepository(error: Exception(LocationRepository.blockedMessage));
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Seleccionar ubicación'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Centrar en mi ubicación'));
      await tester.pumpAndSettle();

      expect(find.text('Ubicación bloqueada'), findsOneWidget);
      expect(find.text(LocationRepository.blockedMessage), findsOneWidget);

      await tester.tap(find.text('Abrir ajustes'));
      await tester.pumpAndSettle();

      expect(fakeLocationRepo.openSettingsCalls, 1);
      expect(find.text('Ubicación bloqueada'), findsNothing);
    });

    testWidgets('completing Step 1 advances to Step 2 with Colombian category and severity selection', (tester) async {
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pumpAndSettle();

      // Enter structured nomenclature
      await tester.enterText(find.byType(TextField).at(0), '5');
      await tester.enterText(find.byType(TextField).at(1), '38');
      await tester.enterText(find.byType(TextField).at(2), '00');
      await tester.enterText(find.byType(TextField).at(3), 'San Fernando');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Confirmar ubicación'));
      await tester.tap(find.text('Confirmar ubicación'));
      await tester.pumpAndSettle();

      // Now at Step 2
      expect(find.text('Paso 2 de 5'), findsOneWidget);
      expect(find.text('¿Qué tipo de daño es?'), findsOneWidget);
      expect(find.text('Hueco o bache en calzada'), findsOneWidget);
      expect(find.text('Semáforo dañado o apagado'), findsOneWidget);
      expect(find.text('Baja'), findsOneWidget);
      expect(find.text('Media'), findsOneWidget);
      expect(find.text('Alta'), findsOneWidget);
      expect(find.text('Crítica'), findsOneWidget);
    });

    testWidgets('attempting to close wizard with draft data prompts discard confirmation', (tester) async {
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pumpAndSettle();

      // Enter reference point address
      await tester.tap(find.text('Punto de referencia'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Frente al parque San Fernando');
      await tester.enterText(find.byType(TextField).at(1), 'San Fernando');
      await tester.ensureVisible(find.text('Confirmar ubicación'));
      await tester.tap(find.text('Confirmar ubicación'));
      await tester.pumpAndSettle();

      // Tap close button (top right icon)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('¿Descartar este reporte?'), findsOneWidget);
      expect(find.text('Seguir editando'), findsOneWidget);
      expect(find.text('Descartar reporte'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Seguir editando'));
      await tester.pumpAndSettle();
      expect(find.text('¿Descartar este reporte?'), findsNothing);
    });
  });
}

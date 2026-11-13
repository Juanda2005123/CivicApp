import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_category.dart';
import 'package:vigia_app/features/reports/domain/usecases/create_incident_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/endorse_incident_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_categories_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_nearby_incidents_usecase.dart';
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
    });

    ReportWizardBloc newBloc() {
      final bloc = ReportWizardBloc(
        GetCategoriesUseCase(fakeCategoryRepo),
        GetNearbyIncidentsUseCase(fakeIncidentRepo),
        CreateIncidentUseCase(fakeIncidentRepo),
        EndorseIncidentUseCase(fakeIncidentRepo),
        GetCurrentProfileUseCase(fakeAuthRepo, fakeProfileRepo),
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

    testWidgets('renders Step 1 with map location pin title and fields', (tester) async {
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pumpAndSettle();

      expect(find.text('Paso 1 de 5'), findsOneWidget);
      expect(find.text('Ubica el daño en el mapa'), findsOneWidget);
      expect(find.text('Confirmar ubicación'), findsOneWidget);
      expect(find.text('Dirección o punto de referencia'), findsOneWidget);
      expect(find.text('Barrio o sector'), findsOneWidget);
    });

    testWidgets('completing Step 1 advances to Step 2 with category and severity selection', (tester) async {
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pumpAndSettle();

      // Enter address and neighborhood
      await tester.enterText(find.byType(TextField).first, 'Calle 5 # 38-00');
      await tester.enterText(find.byType(TextField).at(1), 'San Fernando');
      await tester.ensureVisible(find.text('Confirmar ubicación'));
      await tester.tap(find.text('Confirmar ubicación'));
      await tester.pumpAndSettle();

      // Now at Step 2
      expect(find.text('Paso 2 de 5'), findsOneWidget);
      expect(find.text('¿Qué tipo de daño es?'), findsOneWidget);
      expect(find.text('Hueco'), findsOneWidget);
      expect(find.text('Baja'), findsOneWidget);
      expect(find.text('Media'), findsOneWidget);
      expect(find.text('Alta'), findsOneWidget);
      expect(find.text('Crítica'), findsOneWidget);
    });

    testWidgets('attempting to close wizard with draft data prompts discard confirmation', (tester) async {
      final bloc = newBloc();
      await tester.pumpWidget(createWidgetUnderTest(bloc));
      await tester.pumpAndSettle();

      // Enter address and confirm to reach step 2 (draft has data)
      await tester.enterText(find.byType(TextField).first, 'Calle 5 # 38-00');
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

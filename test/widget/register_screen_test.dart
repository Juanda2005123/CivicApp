import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/app_routes.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/widgets/primary_button.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/usecases/detect_nearest_city_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_cities_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:vigia_app/features/auth/ui/bloc/register_bloc.dart';
import 'package:vigia_app/features/auth/ui/bloc/register_event.dart';
import 'package:vigia_app/features/auth/ui/screens/register_screen.dart';

import '../support/fakes.dart';

const _cali = City(
  id: 1,
  name: 'Cali',
  department: 'Valle del Cauca',
  latitude: 3.4516,
  longitude: -76.5320,
  isCapital: true,
  kind: CityKind.capital,
  radiusKm: 18.0,
);
const _pasto = City(
  id: 2,
  name: 'Pasto',
  department: 'Nariño',
  latitude: 1.2136,
  longitude: -77.2811,
  isCapital: true,
);

Widget createRegisterTestWidget(RegisterBloc bloc) {
  return BlocProvider<RegisterBloc>.value(
    value: bloc..add(RegisterStarted()),
    child: MaterialApp(
      theme: AppTheme.light,
      home: const RegisterScreen(),
      routes: {
        AppRoutes.dashboard: (context) => const Scaffold(body: Text('Dashboard Screen Mock')),
      },
    ),
  );
}

final createButton = find.widgetWithText(PrimaryButton, 'Crear cuenta');

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;
  late FakeLocationRepository location;
  late RegisterBloc bloc;

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  // Created inside each test: a bloc built in setUp would run its event loop in
  // the real zone, outside the widget tester's fake async.
  RegisterBloc newBloc() {
    final cities = FakeCityRepository(const [_cali, _pasto]);
    final created = RegisterBloc(
      GetCitiesUseCase(cities),
      DetectNearestCityUseCase(location, cities),
      SignUpUseCase(auth, profiles),
    );
    addTearDown(created.close);
    return created;
  }

  setUp(() {
    final calls = <String>[];
    auth = FakeAuthRepository(calls: calls);
    profiles = FakeProfileRepository(calls: calls);
    location = FakeLocationRepository(
      coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
    );
  });

  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'Ana Gomez');
    await tester.enterText(find.byType(TextField).at(1), 'ana@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'Abc123');
    await tester.enterText(find.byType(TextField).at(3), 'Abc123');
  }

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders all registration fields and placeholder', (tester) async {
      useTallScreen(tester);

      await tester.pumpWidget(createRegisterTestWidget(bloc = newBloc()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Crear cuenta'), findsOneWidget);
      expect(find.textContaining('Únete a la veeduría'), findsOneWidget);
      expect(find.text('Ej. Juan David Quintero'), findsOneWidget);
      expect(find.text('Ciudad de residencia'), findsOneWidget);
      expect(find.text('Detectar mi ciudad por GPS'), findsOneWidget);
      expect(createButton, findsOneWidget);
    });

    testWidgets('validates full name requiring at least two words', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(createRegisterTestWidget(bloc = newBloc()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Juan');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Escribe tu nombre y apellido'), findsOneWidget);
    });

    testWidgets('enforces strict password complexity rules (uppercase, lowercase, number)', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(createRegisterTestWidget(bloc = newBloc()));
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextField).at(2);
      final submitButton = createButton;

      final cases = {
        'Ab1': 'Usa al menos 6 caracteres',
        'abcdef1': 'Incluye una letra mayúscula',
        'ABCDEF1': 'Incluye una letra minúscula',
        'Abcdefg': 'Incluye un número',
      };
      for (final entry in cases.entries) {
        await tester.enterText(passwordField, entry.key);
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('validates password confirmation match', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(createRegisterTestWidget(bloc = newBloc()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), 'Password123');
      await tester.enterText(find.byType(TextField).at(3), 'Different123');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('the live checklist follows the password rules', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(createRegisterTestWidget(bloc = newBloc()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsNothing);

      await tester.enterText(find.byType(TextField).at(2), 'Abc123');
      await tester.pump();

      expect(find.byIcon(Icons.check_circle_outline), findsNWidgets(4));
    });

    testWidgets('the GPS button selects the nearest city through the bloc', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(createRegisterTestWidget(bloc = newBloc()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Detectar mi ciudad por GPS'));
      await tester.pumpAndSettle();

      expect(find.text('Ciudad detectada: Cali (Valle del Cauca)'), findsOneWidget);
      expect(bloc.state.selectedCity, _cali);
    });

    testWidgets('a GPS failure shows its message and leaves the city unselected', (tester) async {
      useTallScreen(tester);
      location = FakeLocationRepository(error: Exception('Permission denied.'));

      await tester.pumpWidget(createRegisterTestWidget(bloc = newBloc()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Detectar mi ciudad por GPS'));
      await tester.pumpAndSettle();

      expect(find.text('Permission denied.'), findsOneWidget);
      expect(bloc.state.selectedCity, isNull);
    });

    testWidgets('a valid form creates the account and the profile, then opens the dashboard', (tester) async {
      useTallScreen(tester);
      await tester.pumpWidget(createRegisterTestWidget(bloc = newBloc()));
      await tester.pumpAndSettle();

      await fillValidForm(tester);
      await tester.tap(find.text('Detectar mi ciudad por GPS'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(auth.calls, ['auth.signUp', 'profile.create']);
      expect(profiles.stored['uid-1']?.cityName, 'Cali');
      expect(find.text('Dashboard Screen Mock'), findsOneWidget);
    });

    testWidgets('a repeated email shows the error and stays on the form', (tester) async {
      useTallScreen(tester);
      auth.signUpError = Exception('Ese correo ya está registrado en VIGÍA.');
      await tester.pumpWidget(createRegisterTestWidget(bloc = newBloc()));
      await tester.pumpAndSettle();

      await fillValidForm(tester);
      await tester.tap(find.text('Detectar mi ciudad por GPS'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Ese correo ya está registrado en VIGÍA.'), findsOneWidget);
      expect(find.text('Dashboard Screen Mock'), findsNothing);
      expect(profiles.stored, isEmpty);
    });
  });
}

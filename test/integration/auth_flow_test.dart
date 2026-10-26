import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/di/injection_container.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/main.dart';

import '../support/fakes.dart';

const _cali = City(
  id: 1,
  name: 'Cali',
  department: 'Valle del Cauca',
  latitude: 3.4516,
  longitude: -76.5320,
  isCapital: true,
);

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;

  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
  }

  /// Boots the real app: real routes, blocs, use cases and GetIt wiring, with
  /// the repositories replaced by fakes (no network, no Supabase).
  Future<void> bootApp(WidgetTester tester) async {
    await initDependencies(
      authRepository: auth,
      profileRepository: profiles,
      cityRepository: FakeCityRepository(const [_cali]),
      locationRepository: FakeLocationRepository(
        coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
      ),
    );
    await tester.pumpWidget(const VigiaApp());
    await tester.pumpAndSettle();
  }

  setUp(() {
    final calls = <String>[];
    auth = FakeAuthRepository(calls: calls);
    profiles = FakeProfileRepository(calls: calls);
  });

  tearDown(() => sl.reset());

  testWidgets(
    'Complete End-to-End Civic Auth Flow: Splash -> Login -> Register -> Dashboard -> Logout -> Login -> Dashboard',
    (WidgetTester tester) async {
      useTallScreen(tester);

      // 1. The splash finds no session and routes to the login
      await bootApp(tester);
      expect(find.text('VIGÍA'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);

      // 2. Navigate to the registration
      await tester.tap(find.text('Register here'));
      await tester.pumpAndSettle();
      expect(find.text('Citizen Registration'), findsOneWidget);

      // 3. Fill the form and pick the city from the dropdown
      await tester.enterText(find.byType(TextFormField).at(0), 'Juan David Quintero');
      await tester.enterText(find.byType(TextFormField).at(1), 'juand@vigia.co');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');

      final dropdown = find.byType(DropdownButtonFormField<int>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cali (Valle del Cauca)').last);
      await tester.pumpAndSettle();

      // 4. Submit: account first, profile second, then the summary
      final registerButton = find.text('Create Civic Account');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // The account first, the profile second, then the dashboard loads the profile
      expect(auth.calls, ['auth.signUp', 'profile.create', 'profile.get']);
      expect(find.text('VIGÍA Civic Dashboard'), findsOneWidget);
      expect(find.text('Juan David Quintero'), findsOneWidget);
      expect(find.text('juand@vigia.co'), findsOneWidget);
      expect(find.text('Cali'), findsOneWidget);
      expect(find.text('Urban Observer (Rank 1)'), findsOneWidget);

      // 5. Log out: back to the login, with no way back to the dashboard
      final logoutButton = find.text('Log Out');
      await tester.ensureVisible(logoutButton);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle();

      expect(auth.currentUser(), isNull);
      expect(find.text('Log In'), findsOneWidget);

      // 6. Log in again with the same account
      await tester.enterText(find.byType(TextFormField).at(0), 'juand@vigia.co');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();

      expect(find.text('VIGÍA Civic Dashboard'), findsOneWidget);
      expect(find.text('Juan David Quintero'), findsOneWidget);
    },
  );

  testWidgets('a persisted session skips the login and opens the dashboard', (tester) async {
    useTallScreen(tester);
    auth.user = const AuthUser(id: 'uid-1', email: 'ana@example.com');
    profiles.stored['uid-1'] = caliProfile;

    await bootApp(tester);

    expect(find.text('VIGÍA Civic Dashboard'), findsOneWidget);
    expect(find.text('Ana Gomez'), findsOneWidget);
    expect(find.text('Log In'), findsNothing);
  });
}

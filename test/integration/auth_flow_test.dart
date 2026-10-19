import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/usuario.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/main.dart';

class _FakeIntegrationAuthRepository implements AuthRepository {
  Usuario? _currentUser;

  @override
  Future<User> login({required String email, required String password}) async {
    final user = User(
      id: 'integration-user-1',
      email: email,
      fullName: 'Juan David Quintero',
      residenceCityId: 1,
      cityName: 'Cali (Valle del Cauca)',
      rankId: 1,
      rankName: 'Urban Observer',
      reputationPoints: 0,
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required int cityId,
    String? cityName,
  }) async {
    final user = User(
      id: 'integration-user-2',
      email: email,
      fullName: fullName,
      residenceCityId: cityId,
      cityName: cityName ?? 'Cali (Valle del Cauca)',
      rankId: 1,
      rankName: 'Observador',
      reputationPoints: 0,
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<Usuario?> getCurrentUser() async {
    return _currentUser;
  }
}

void main() {
  testWidgets('Complete End-to-End Civic Auth Flow: Boot -> Register -> Dashboard -> Logout -> Login -> Dashboard',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeRepo = _FakeIntegrationAuthRepository();

    // 1. Boot Application
    await tester.pumpWidget(VigiaApp(customAuthRepository: fakeRepo));
    await tester.pumpAndSettle();

    // Verify initial Login Screen
    expect(find.text('VIGÍA'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);

    // 2. Navigate to Register Screen
    await tester.tap(find.text('Regístrate aquí'));
    await tester.pumpAndSettle();

    expect(find.text('Registro de Ciudadano'), findsOneWidget);

    // 3. Fill Registration Form
    await tester.enterText(find.byType(TextFormField).at(0), 'Juan David Quintero');
    await tester.enterText(find.byType(TextFormField).at(1), 'juand@vigia.co');
    await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
    await tester.enterText(find.byType(TextFormField).at(3), 'Password123');

    // Select City in DANE Dropdown
    final dropdownFinder = find.byType(DropdownButtonFormField<int>);
    expect(dropdownFinder, findsOneWidget);
    await tester.ensureVisible(dropdownFinder);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    // Tap 'Cali (Valle del Cauca)' item
    await tester.tap(find.text('Cali (Valle del Cauca)').last);
    await tester.pumpAndSettle();

    // 4. Submit Registration
    final registerBtn = find.text('Crear Cuenta Cívica');
    await tester.ensureVisible(registerBtn);
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();

    // Verify Dashboard is displayed with citizen details
    expect(find.text('Panel Cívico VIGÍA'), findsOneWidget);
    expect(find.text('¡Te has logueado con éxito!'), findsOneWidget);
    expect(find.text('Juan David Quintero'), findsOneWidget);
    expect(find.text('juand@vigia.co'), findsOneWidget);
    expect(find.text('Observador (Rango 1)'), findsOneWidget);

    // 5. Logout
    final logoutBtn = find.text('Salir / Desloguearse');
    await tester.ensureVisible(logoutBtn);
    await tester.tap(logoutBtn);
    await tester.pumpAndSettle();

    // Verify redirected to Login Screen and backstack is clean
    expect(find.text('VIGÍA'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);

    // 6. Login again with valid credentials
    await tester.enterText(find.byType(TextFormField).at(0), 'juand@vigia.co');
    await tester.enterText(find.byType(TextFormField).at(1), 'Password123');
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    // Verify landed safely on Dashboard again
    expect(find.text('Panel Cívico VIGÍA'), findsOneWidget);
    expect(find.text('¡Te has logueado con éxito!'), findsOneWidget);
  });
}

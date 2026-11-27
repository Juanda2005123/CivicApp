import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/theme/theme_cubit.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/city_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/detect_nearest_city_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_cities_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/open_location_settings_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/update_personal_info_usecase.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/edit_profile_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/edit_profile_event.dart';
import 'package:vigia_app/features/dashboard/ui/screens/edit_profile_screen.dart';

class _FakeProfileRepo implements ProfileRepository {
  @override
  Future<void> createProfile(Profile profile) async {}
  @override
  Future<Profile> getProfile(String id) async => throw UnimplementedError();
  @override
  Future<void> updateLastCity(String id, String cityName) async {}
  @override
  Future<void> updatePrivacy({required String userId, required bool showRealName}) async {}
  @override
  Future<String> updateAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async =>
      '';
  @override
  Future<void> updateProfileInfo({
    required String userId,
    required String fullName,
    required String cityName,
  }) async {}
}

class _FakeAuthRepo implements AuthRepository {
  @override
  AuthUser? currentUser() => const AuthUser(id: 'u1', email: 'ana@vigia.co');
  @override
  Future<AuthUser> signIn({required String email, required String password}) async =>
      throw UnimplementedError();
  @override
  Future<void> signOut() async {}
  @override
  Future<AuthUser> signUp({required String email, required String password}) async =>
      throw UnimplementedError();
  @override
  Future<void> updateEmail(String newEmail) async {}
  @override
  Future<void> updatePassword({
    required String currentEmail,
    required String currentPassword,
    required String newPassword,
  }) async {}
}

class _FakeCityRepo implements CityRepository {
  @override
  Future<List<City>> getCities() async => const [
        City(id: 1, name: 'Cali', department: 'Valle del Cauca', latitude: 3.45, longitude: -76.53, isCapital: true),
      ];
}

class _FakeLocationRepo implements LocationRepository {
  @override
  Future<Coordinates> currentCoordinates() async => const Coordinates(latitude: 3.45, longitude: -76.53);
  @override
  Future<bool> openSettings() async => true;
}

void main() {
  const profile = Profile(
    id: 'u1',
    email: 'ana@vigia.co',
    fullName: 'Ana Gómez',
    cityName: 'Cali',
  );

  Widget buildSubject() {
    final locationRepo = _FakeLocationRepo();
    final cityRepo = _FakeCityRepo();
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(
          create: (_) => EditProfileBloc(
            GetCitiesUseCase(cityRepo),
            DetectNearestCityUseCase(locationRepo, cityRepo),
            OpenLocationSettingsUseCase(locationRepo),
            UpdatePersonalInfoUseCase(_FakeProfileRepo(), _FakeAuthRepo()),
            ChangePasswordUseCase(_FakeAuthRepo()),
          )..add(EditProfileStarted(profile)),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const EditProfileScreen(initialProfile: profile),
      ),
    );
  }

  testWidgets('renders current name, city, email and password change section', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Datos personales'), findsWidgets);
    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('ana@vigia.co'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.text('Actualizar contraseña'), findsOneWidget);
  });

  testWidgets('preserves draft inputs and shows validation error for single-word name', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Ana Gómez'), 'Ana');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu nombre y apellido'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
  });
}

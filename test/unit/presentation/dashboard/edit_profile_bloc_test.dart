import 'package:flutter_test/flutter_test.dart';
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
import 'package:vigia_app/features/dashboard/ui/bloc/edit_profile_state.dart';

class _FakeProfileRepo implements ProfileRepository {
  Exception? error;
  @override
  Future<void> createProfile(Profile profile) async {}
  @override
  Future<Profile> getProfile(String id) async => throw UnimplementedError();
  @override
  Future<void> updateLastCity(String id, String cityName) async {}
  @override
  Future<void> updateProfileInfo({
    required String userId,
    required String fullName,
    required String cityName,
  }) async {
    if (error != null) throw error!;
  }
}

class _FakeAuthRepo implements AuthRepository {
  Exception? passwordError;
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
  }) async {
    if (passwordError != null) throw passwordError!;
  }
}

class _FakeCityRepo implements CityRepository {
  @override
  Future<List<City>> getCities() async => const [
        City(id: 1, name: 'Cali', department: 'Valle del Cauca', latitude: 3.45, longitude: -76.53, isCapital: true),
        City(id: 2, name: 'Medellín', department: 'Antioquia', latitude: 6.24, longitude: -75.57, isCapital: true),
      ];
}

class _FakeLocationRepo implements LocationRepository {
  @override
  Future<Coordinates> currentCoordinates() async => const Coordinates(latitude: 3.45, longitude: -76.53);
  @override
  Future<bool> openSettings() async => true;
}

void main() {
  late _FakeProfileRepo profileRepo;
  late _FakeAuthRepo authRepo;
  late EditProfileBloc bloc;

  const profile = Profile(
    id: 'u1',
    email: 'ana@vigia.co',
    fullName: 'Ana Gómez',
    cityName: 'Cali',
  );

  setUp(() {
    profileRepo = _FakeProfileRepo();
    authRepo = _FakeAuthRepo();
    bloc = EditProfileBloc(
      GetCitiesUseCase(_FakeCityRepo()),
      DetectNearestCityUseCase(_FakeLocationRepo(), _FakeCityRepo()),
      OpenLocationSettingsUseCase(_FakeLocationRepo()),
      UpdatePersonalInfoUseCase(profileRepo, authRepo),
      ChangePasswordUseCase(authRepo),
    );
  });

  tearDown(() => bloc.close());

  test('EditProfileStarted loads DANE cities', () async {
    bloc.add(EditProfileStarted(profile));
    await expectLater(
      bloc.stream,
      emitsThrough(predicate<EditProfileState>((s) => s.cities.length == 2 && s.profile == profile)),
    );
  });

  test('EditProfileSaved emits saved with emailVerificationPending when email changes', () async {
    bloc.add(EditProfileStarted(profile));
    await Future<void>.delayed(Duration.zero);

    bloc.add(EditProfileSaved(fullName: 'Ana Gómez', cityName: 'Medellín', email: 'nueva@vigia.co'));
    await expectLater(
      bloc.stream,
      emitsThrough(predicate<EditProfileState>(
        (s) => s.status == EditProfileStatus.saved && s.emailVerificationPending,
      )),
    );
  });

  test('EditProfilePasswordChanged emits failure when current password is wrong', () async {
    authRepo.passwordError = Exception('La contraseña actual es incorrecta.');
    bloc.add(EditProfileStarted(profile));
    await Future<void>.delayed(Duration.zero);

    bloc.add(EditProfilePasswordChanged(currentPassword: 'Wrong1', newPassword: 'NewPassword2'));
    await expectLater(
      bloc.stream,
      emitsThrough(predicate<EditProfileState>(
        (s) =>
            s.passwordStatus == PasswordChangeStatus.failure &&
            s.passwordErrorMessage == 'La contraseña actual es incorrecta.',
      )),
    );
  });
}

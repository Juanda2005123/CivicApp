import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/city_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';

/// Records every call so tests can assert the order of the steps.
class FakeAuthRepository implements AuthRepository {
  final List<String> calls;
  AuthUser? user;
  Exception? signUpError;
  Exception? signInError;

  FakeAuthRepository({List<String>? calls, this.user}) : calls = calls ?? [];

  @override
  Future<AuthUser> signUp({required String email, required String password}) async {
    calls.add('auth.signUp');
    if (signUpError != null) throw signUpError!;
    user = AuthUser(id: 'uid-1', email: email);
    return user!;
  }

  @override
  Future<AuthUser> signIn({required String email, required String password}) async {
    calls.add('auth.signIn');
    if (signInError != null) throw signInError!;
    user = AuthUser(id: 'uid-1', email: email);
    return user!;
  }

  @override
  Future<void> signOut() async {
    calls.add('auth.signOut');
    user = null;
  }

  @override
  AuthUser? currentUser() => user;
}

class FakeProfileRepository implements ProfileRepository {
  final List<String> calls;
  final Map<String, Profile> stored = {};
  Exception? createError;
  Exception? getError;

  FakeProfileRepository({List<String>? calls}) : calls = calls ?? [];

  @override
  Future<void> createProfile(Profile profile) async {
    calls.add('profile.create');
    if (createError != null) throw createError!;
    stored[profile.id] = profile;
  }

  @override
  Future<Profile> getProfile(String id) async {
    calls.add('profile.get');
    if (getError != null) throw getError!;
    final profile = stored[id];
    if (profile == null) throw Exception('Civic profile not found');
    return profile;
  }
}

class FakeCityRepository implements CityRepository {
  final List<City> cities;
  FakeCityRepository(this.cities);

  @override
  Future<List<City>> getCities() async => cities;
}

class FakeLocationRepository implements LocationRepository {
  final Coordinates? coordinates;
  final Exception? error;
  FakeLocationRepository({this.coordinates, this.error});

  @override
  Future<Coordinates> currentCoordinates() async {
    if (error != null) throw error!;
    return coordinates!;
  }
}

const caliProfile = Profile(
  id: 'uid-1',
  email: 'ana@example.com',
  fullName: 'Ana Gomez',
  cityName: 'Cali',
);

import 'dart:async';

import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/city_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_category.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_photo.dart';
import 'package:vigia_app/features/reports/domain/entities/nearby_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:vigia_app/features/reports/domain/repositories/category_repository.dart';
import 'package:vigia_app/features/reports/domain/repositories/incident_repository.dart';

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

  /// When set, getProfile waits for it: lets a test observe the loading state.
  Completer<void>? gate;

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
    if (gate != null) await gate!.future;
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

class FakeCategoryRepository implements CategoryRepository {
  final List<IncidentCategory> categories;
  Exception? error;

  FakeCategoryRepository({this.categories = const [], this.error});

  @override
  Future<List<IncidentCategory>> getCategories() async {
    if (error != null) throw error!;
    return categories;
  }
}

class FakeIncidentRepository implements IncidentRepository {
  final List<String> calls = [];
  final Map<String, Incident> stored = {};
  List<NearbyIncident> nearbyToReturn = [];
  Exception? createError;
  Exception? getError;

  @override
  Future<Incident> createIncident({
    required String reporterId,
    required int categoryId,
    required String title,
    required String description,
    required IncidentSeverity severity,
    String? estimatedDimensions,
    required Coordinates coordinates,
    required String formattedAddress,
    required String neighborhood,
    required String city,
    required List<PickedPhoto> photos,
  }) async {
    calls.add('incident.create');
    if (createError != null) throw createError!;

    final created = Incident(
      id: 'incident-${stored.length + 1}',
      trackingCode: '#VIG-100${stored.length + 1}',
      reporterId: reporterId,
      categoryId: categoryId,
      title: title,
      description: description,
      severity: severity,
      estimatedDimensions: estimatedDimensions,
      coordinates: coordinates,
      formattedAddress: formattedAddress,
      neighborhood: neighborhood,
      city: city,
      photos: photos
          .asMap()
          .entries
          .map((e) => IncidentPhoto(
                id: 'photo-${e.key + 1}',
                incidentId: 'incident-${stored.length + 1}',
                fileUrl: 'https://example.com/photo-${e.key + 1}.jpg',
                isPrimary: e.key == 0,
                uploadedAt: DateTime(2026, 11, 12),
              ))
          .toList(),
      createdAt: DateTime(2026, 11, 12),
    );
    stored[created.id] = created;
    stored[created.trackingCode] = created;
    return created;
  }

  @override
  Future<List<NearbyIncident>> getNearbyIncidents({
    required Coordinates coordinates,
    required int categoryId,
    double radiusInMeters = 150.0,
  }) async {
    calls.add('incident.getNearby');
    return nearbyToReturn;
  }

  @override
  Future<Incident> getIncidentById(String idOrTrackingCode) async {
    calls.add('incident.getById');
    if (getError != null) throw getError!;
    final incident = stored[idOrTrackingCode];
    if (incident == null) throw Exception('Reporte no encontrado');
    return incident;
  }

  @override
  Future<void> endorseIncident({
    required String incidentId,
    required String userId,
  }) async {
    calls.add('incident.endorse');
  }
}

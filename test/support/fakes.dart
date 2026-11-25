import 'dart:async';
import 'dart:typed_data';

import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/city.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/city_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';
import 'package:vigia_app/features/explore/domain/repositories/recent_cities_repository.dart';
import 'package:vigia_app/features/reports/domain/entities/address_match.dart';
import 'package:vigia_app/features/reports/domain/entities/geocoded_place.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_category.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_marker.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_photo.dart';
import 'package:vigia_app/features/reports/domain/entities/nearby_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:vigia_app/features/reports/domain/repositories/category_repository.dart';
import 'package:vigia_app/features/reports/domain/repositories/geocoding_repository.dart';
import 'package:vigia_app/features/reports/domain/repositories/incident_repository.dart';
import 'package:vigia_app/features/reports/domain/repositories/photo_picker_repository.dart';

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

  Exception? updateLastCityError;

  @override
  Future<void> updateLastCity(String id, String cityName) async {
    calls.add('profile.updateLastCity');
    if (updateLastCityError != null) throw updateLastCityError!;
    final profile = stored[id];
    if (profile == null) throw Exception('Civic profile not found');
    stored[id] = Profile(
      id: profile.id,
      email: profile.email,
      fullName: profile.fullName,
      cityName: profile.cityName,
      lastCityName: cityName,
      rankId: profile.rankId,
      rankName: profile.rankName,
      experiencePoints: profile.experiencePoints,
      avatarUrl: profile.avatarUrl,
      isActive: profile.isActive,
    );
  }

  @override
  Future<String> updateAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    calls.add('profile.updateAvatar');
    return 'https://example.com/avatars/$userId/avatar.$extension';
  }
}

class FakeRecentCitiesRepository implements RecentCitiesRepository {
  List<String> names;
  FakeRecentCitiesRepository([this.names = const []]);

  @override
  Future<List<String>> getRecentNames() async => names;

  @override
  Future<void> saveRecentNames(List<String> names) async => this.names = names;
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

  /// What [openSettings] answers; `false` simulates a platform (e.g. the web)
  /// that cannot open the system settings.
  final bool canOpenSettings;
  int openSettingsCalls = 0;

  /// Thrown by the first call only: e.g. the citizen denies the dialog the map
  /// shows on open, then allows it from the button.
  Exception? firstCallError;
  int calls = 0;

  FakeLocationRepository({this.coordinates, this.error, this.canOpenSettings = true, this.firstCallError});

  @override
  Future<Coordinates> currentCoordinates() async {
    calls++;
    final once = firstCallError;
    if (once != null) {
      firstCallError = null;
      throw once;
    }
    if (error != null) throw error!;
    return coordinates!;
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return canOpenSettings;
  }
}

class FakeGeocodingRepository implements GeocodingRepository {
  GeocodedPlace place;
  Exception? error;
  int calls = 0;

  /// Answers of [streetAt], in order; past the end it answers an empty place.
  List<GeocodedPlace> streetAnswers;
  Exception? streetError;
  final List<Coordinates> streetQueries = [];

  /// What each typed-address query finds (HU-28). A query that is not here
  /// finds nothing (null), like the real service; [addressError] makes it fail.
  final Map<String, AddressMatch> addressResults = {};
  final List<String> addressQueries = [];
  Exception? addressError;

  FakeGeocodingRepository({this.place = const GeocodedPlace(), this.error, this.streetAnswers = const []});

  @override
  Future<GeocodedPlace> reverseGeocode(Coordinates coordinates) async {
    calls++;
    if (error != null) throw error!;
    return place;
  }

  @override
  Future<GeocodedPlace> streetAt(Coordinates coordinates) async {
    streetQueries.add(coordinates);
    if (streetError != null) throw streetError!;
    final index = streetQueries.length - 1;
    return index < streetAnswers.length ? streetAnswers[index] : const GeocodedPlace();
  }

  @override
  Future<AddressMatch?> geocodeAddress(String query) async {
    addressQueries.add(query);
    if (addressError != null) throw addressError!;
    return addressResults[query];
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
  List<IncidentMarker> cityMarkers = [];
  String? lastCity;

  /// Every report of the feed, newest first; [getCityFeed] slices it like the
  /// database does.
  List<FeedIncident> feed = [];
  Exception? feedError;
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
  Future<List<IncidentMarker>> getCityIncidents(String city) async {
    calls.add('incident.getCityIncidents');
    lastCity = city;
    return cityMarkers;
  }

  @override
  Future<List<FeedIncident>> getCityFeed(String city, {required int offset, int limit = 20}) async {
    calls.add('incident.getCityFeed');
    lastCity = city;
    if (feedError != null) throw feedError!;
    return feed.skip(offset).take(limit).toList();
  }

  @override
  Future<Incident> getIncidentById(String idOrTrackingCode) async {
    calls.add('incident.getById');
    if (getError != null) throw getError!;
    final incident = stored[idOrTrackingCode];
    if (incident == null) throw Exception('Reporte no encontrado');
    return incident;
  }

  Exception? endorseError;
  Exception? revokeError;

  /// When set, endorse and revoke wait for it: lets a test see the optimistic state.
  Completer<void>? endorseGate;

  @override
  Future<void> endorseIncident({
    required String incidentId,
    required String userId,
  }) async {
    calls.add('incident.endorse');
    if (endorseGate != null) await endorseGate!.future;
    if (endorseError != null) throw endorseError!;
    // Like the database trigger: the 10th endorsement validates the report.
    _updateStored(incidentId, (incident) {
      final endorsed = incident.withEndorsementBy(userId);
      if (endorsed.upvotesCount >= Incident.validationTarget && !endorsed.isCommunityValidated) {
        return endorsed.copyWith(
          status: IncidentStatus.communityValidated,
          validatedAt: DateTime(2026, 11, 16),
        );
      }
      return endorsed;
    });
  }

  @override
  Future<void> revokeEndorsement({
    required String incidentId,
    required String userId,
  }) async {
    calls.add('incident.revoke');
    if (endorseGate != null) await endorseGate!.future;
    if (revokeError != null) throw revokeError!;
    _updateStored(incidentId, (incident) => incident.withoutEndorsementBy(userId));
  }

  Exception? updateError;
  Exception? deleteError;

  /// Reports deleted, by id.
  final List<String> deletedIds = [];

  /// Like the server: the report keeps its code and place, the photos follow the
  /// edit, and a frozen report (window over or 5 endorsements) is refused.
  @override
  Future<Incident> updateIncident({
    required String incidentId,
    required String reporterId,
    required int categoryId,
    required String title,
    required String description,
    required IncidentSeverity severity,
    String? estimatedDimensions,
    required List<IncidentPhoto> removedPhotos,
    required List<PickedPhoto> addedPhotos,
  }) async {
    calls.add('incident.update');
    if (updateError != null) throw updateError!;
    final current = stored[incidentId];
    if (current == null) throw Exception('Reporte no encontrado');

    final removedIds = removedPhotos.map((p) => p.id).toSet();
    final photos = [
      ...current.photos.where((p) => !removedIds.contains(p.id)),
      for (final (i, _) in addedPhotos.indexed)
        IncidentPhoto(
          id: 'new-photo-${current.photos.length + i + 1}',
          incidentId: incidentId,
          fileUrl: 'https://example.com/new-${current.photos.length + i + 1}.jpg',
          uploadedAt: DateTime(2026, 11, 12),
        ),
    ];
    final updated = current.copyWith(
      categoryId: categoryId,
      title: title,
      description: description,
      severity: severity,
      estimatedDimensions: estimatedDimensions,
      clearEstimatedDimensions: estimatedDimensions == null,
      photos: photos,
    );
    _storeUpdated(current, updated);
    return updated;
  }

  @override
  Future<void> deleteIncident(Incident incident) async {
    calls.add('incident.delete');
    if (deleteError != null) throw deleteError!;
    deletedIds.add(incident.id);
    stored.remove(incident.id);
    stored.remove(incident.trackingCode);
  }

  void _storeUpdated(Incident current, Incident updated) {
    stored[current.id] = updated;
    stored[current.trackingCode] = updated;
  }

  /// Mimics the server: the stored report reflects the endorsement, so a later
  /// read of the report shows it.
  void _updateStored(String incidentId, Incident Function(Incident) change) {
    final current = stored[incidentId];
    if (current == null) return;
    final updated = change(current);
    stored[current.id] = updated;
    stored[current.trackingCode] = updated;
  }
}

class FakePhotoPickerRepository implements PhotoPickerRepository {
  PickedPhoto? photoToReturn;
  Exception? error;

  FakePhotoPickerRepository({this.photoToReturn, this.error});

  @override
  Future<PickedPhoto?> pickPhoto({bool fromCamera = false}) async {
    if (error != null) throw error!;
    return photoToReturn;
  }
}

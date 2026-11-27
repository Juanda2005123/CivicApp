import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/data/datasources/incident_remote_data_source.dart';
import 'package:vigia_app/features/reports/data/datasources/photo_storage_data_source.dart';
import 'package:vigia_app/features/reports/data/models/incident_model.dart';
import 'package:vigia_app/features/reports/data/repositories/incident_repository_impl.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_photo.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_marker.dart';
import 'package:vigia_app/features/reports/domain/entities/nearby_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';

class FakePhotoStorageDataSource implements PhotoStorageDataSource {
  final List<String> calls = [];
  String urlToReturn = 'https://supabase.co/storage/photo.jpg';
  Exception? uploadError;

  @override
  Future<String> uploadPhoto({
    required Uint8List bytes,
    required String extension,
    required String reporterId,
  }) async {
    calls.add('storage.uploadPhoto');
    if (uploadError != null) throw uploadError!;
    return urlToReturn;
  }
}

class FakeIncidentRemoteDataSource implements IncidentRemoteDataSource {
  final List<String> calls = [];
  IncidentModel? lastInserted;
  List<NearbyIncident> nearbyToReturn = [];

  @override
  Future<IncidentModel> insertIncident({
    required IncidentModel incident,
    required List<String> photoUrls,
  }) async {
    calls.add('remote.insertIncident');
    lastInserted = incident;
    return incident;
  }

  @override
  Future<List<NearbyIncident>> getNearbyIncidents({
    required double latitude,
    required double longitude,
    required int categoryId,
    double radiusInMeters = 150.0,
  }) async {
    calls.add('remote.getNearbyIncidents');
    return nearbyToReturn;
  }

  @override
  Future<List<IncidentMarker>> getCityIncidents(String city) async {
    calls.add('remote.getCityIncidents');
    return const [];
  }

  int? lastFeedOffset;
  int? lastFeedLimit;

  @override
  Future<List<FeedIncident>> getCityFeed(String city, {required int offset, required int limit}) async {
    calls.add('remote.getCityFeed');
    lastFeedOffset = offset;
    lastFeedLimit = limit;
    return const [];
  }

  @override
  Future<IncidentModel> getIncidentById(String idOrTrackingCode) async {
    calls.add('remote.getIncidentById');
    if (lastInserted != null) return lastInserted!;
    throw Exception('No encontrado');
  }

  Exception? updateRowError;
  Exception? replacePhotosError;
  List<String>? lastRemovedPhotoIds;
  List<String>? lastNewPhotoUrls;
  String? lastDeletedId;

  @override
  Future<void> updateIncidentRow({
    required String incidentId,
    required int categoryId,
    required String title,
    required String description,
    required IncidentSeverity severity,
    String? estimatedDimensions,
  }) async {
    calls.add('remote.updateIncidentRow');
    if (updateRowError != null) throw updateRowError!;
  }

  @override
  Future<void> replacePhotos({
    required String incidentId,
    required List<String> removedPhotoIds,
    required List<String> newPhotoUrls,
  }) async {
    calls.add('remote.replacePhotos');
    lastRemovedPhotoIds = removedPhotoIds;
    lastNewPhotoUrls = newPhotoUrls;
    if (replacePhotosError != null) throw replacePhotosError!;
  }

  @override
  Future<void> deleteIncident(String incidentId) async {
    calls.add('remote.deleteIncident');
    lastDeletedId = incidentId;
  }

  @override
  Future<void> revokeEndorsement({required String incidentId, required String userId}) async {
    calls.add('remote.revokeEndorsement');
  }

  @override
  Future<void> endorseIncident({required String incidentId, required String userId}) async {
    calls.add('remote.endorseIncident');
  }
}

void main() {
  group('IncidentRepositoryImpl Tests', () {
    late FakeIncidentRemoteDataSource fakeRemote;
    late FakePhotoStorageDataSource fakeStorage;
    late IncidentRepositoryImpl repository;

    setUp(() {
      fakeRemote = FakeIncidentRemoteDataSource();
      fakeStorage = FakePhotoStorageDataSource();
      repository = IncidentRepositoryImpl(fakeRemote, fakeStorage);
    });

    test('createIncident uploads all photos before inserting the incident', () async {
      final photo = PickedPhoto(
        bytes: Uint8List(10),
        extension: 'jpg',
        sizeInBytes: 100,
      );

      final incident = await repository.createIncident(
        reporterId: 'user-123',
        categoryId: 1,
        title: 'Bache grande',
        description: 'Descripción amplia del bache',
        severity: IncidentSeverity.critical,
        coordinates: const Coordinates(latitude: 3.45, longitude: -76.53),
        formattedAddress: 'Calle 5',
        neighborhood: 'San Fernando',
        city: 'Cali',
        photos: [photo, photo],
      );

      expect(fakeStorage.calls, ['storage.uploadPhoto', 'storage.uploadPhoto']);
      expect(fakeRemote.calls, ['remote.insertIncident']);
      expect(incident.title, 'Bache grande');
      expect(incident.trackingCode, startsWith('#VIG-'));
    });

    group('updateIncident and deleteIncident (HU-18)', () {
      final photo = PickedPhoto(bytes: Uint8List(10), extension: 'jpg', sizeInBytes: 100);
      final removed = IncidentPhoto(
        id: 'photo-1',
        incidentId: 'inc-1',
        fileUrl: 'https://example.com/1.jpg',
        isPrimary: true,
        uploadedAt: DateTime(2026, 11, 12),
      );

      /// The report the fake remote answers the final read with.
      void stageStoredIncident() {
        fakeRemote.lastInserted = IncidentModel(
          id: 'inc-1',
          trackingCode: '#VIG-1001',
          reporterId: 'user-123',
          categoryId: 1,
          title: 'Bache grande',
          description: 'Descripción amplia del bache',
          severity: IncidentSeverity.high,
          coordinates: const Coordinates(latitude: 3.45, longitude: -76.53),
          formattedAddress: 'Calle 5',
          neighborhood: 'San Fernando',
          city: 'Cali',
          createdAt: DateTime(2026, 11, 12),
        );
      }

      Future<Incident> edit({List<IncidentPhoto> removedPhotos = const [], List<PickedPhoto> addedPhotos = const []}) {
        return repository.updateIncident(
          incidentId: 'inc-1',
          reporterId: 'user-123',
          categoryId: 1,
          title: 'Bache grande',
          description: 'Descripción amplia del bache',
          severity: IncidentSeverity.high,
          removedPhotos: removedPhotos,
          addedPhotos: addedPhotos,
        );
      }

      test('a text-only edit saves the row and reads the report again, with no photo work', () async {
        stageStoredIncident();

        await edit();

        expect(fakeRemote.calls, ['remote.updateIncidentRow', 'remote.getIncidentById']);
        expect(fakeStorage.calls, isEmpty);
      });

      test('saves the text first, then uploads the new photos, then replaces the photo rows', () async {
        stageStoredIncident();

        await edit(removedPhotos: [removed], addedPhotos: [photo]);

        expect(fakeRemote.calls, ['remote.updateIncidentRow', 'remote.replacePhotos', 'remote.getIncidentById']);
        expect(fakeStorage.calls, ['storage.uploadPhoto']);
        expect(fakeRemote.lastRemovedPhotoIds, ['photo-1']);
        expect(fakeRemote.lastNewPhotoUrls, ['https://supabase.co/storage/photo.jpg']);
      });

      test('when the server refuses the edit nothing is uploaded and the message is kept', () async {
        fakeRemote.updateRowError = Exception('Este reporte ya no se puede modificar ni eliminar: pasaron más de 30 minutos o tiene 5 apoyos o más.');

        await expectLater(
          edit(addedPhotos: [photo]),
          throwsA(predicate((e) => e.toString().contains('pasaron más de 30 minutos'))),
        );

        expect(fakeStorage.calls, isEmpty);
        expect(fakeRemote.calls, ['remote.updateIncidentRow']);
      });

      test('a photo failure after the text was saved says so', () async {
        fakeStorage.uploadError = Exception('No pudimos subir la foto de evidencia: sin conexión');

        await expectLater(
          edit(addedPhotos: [photo]),
          throwsA(predicate((e) =>
              e.toString().contains('Guardamos los cambios del texto, pero no pudimos actualizar las fotos') &&
              e.toString().contains('sin conexión'))),
        );
      });

      test('deleteIncident asks the data source to delete that report', () async {
        stageStoredIncident();
        final incident = await edit();

        await repository.deleteIncident(incident);

        expect(fakeRemote.lastDeletedId, 'inc-1');
        expect(fakeRemote.calls.last, 'remote.deleteIncident');
      });
    });

    test('getNearbyIncidents delegates to remote data source', () async {
      fakeRemote.nearbyToReturn = [
        const NearbyIncident(
          id: 'inc-1',
          trackingCode: '#VIG-1000',
          title: 'Daño vial',
          categoryId: 1,
          categoryName: 'Hueco',
          severity: 'HIGH',
          distanceInMeters: 50.0,
        )
      ];

      final results = await repository.getNearbyIncidents(
        coordinates: const Coordinates(latitude: 3.45, longitude: -76.53),
        categoryId: 1,
      );

      expect(fakeRemote.calls, ['remote.getNearbyIncidents']);
      expect(results.length, 1);
      expect(results.first.title, 'Daño vial');
    });

    test('getCityFeed delegates the page to the remote data source (HU-19)', () async {
      await repository.getCityFeed('Cali', offset: 40);

      expect(fakeRemote.calls, ['remote.getCityFeed']);
      expect(fakeRemote.lastFeedOffset, 40);
      expect(fakeRemote.lastFeedLimit, 20);
    });

    test('revokeEndorsement delegates to remote data source', () async {
      await repository.revokeEndorsement(incidentId: 'inc-1', userId: 'user-1');

      expect(fakeRemote.calls, ['remote.revokeEndorsement']);
    });

    test('endorseIncident delegates to remote data source', () async {
      await repository.endorseIncident(incidentId: 'inc-1', userId: 'user-1');

      expect(fakeRemote.calls, ['remote.endorseIncident']);
    });

    test('getCityIncidents delegates to remote data source', () async {
      await repository.getCityIncidents('Cali');

      expect(fakeRemote.calls, ['remote.getCityIncidents']);
    });
  });
}

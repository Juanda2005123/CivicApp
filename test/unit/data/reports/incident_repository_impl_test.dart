import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/data/datasources/incident_remote_data_source.dart';
import 'package:vigia_app/features/reports/data/datasources/photo_storage_data_source.dart';
import 'package:vigia_app/features/reports/data/models/incident_model.dart';
import 'package:vigia_app/features/reports/data/repositories/incident_repository_impl.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_marker.dart';
import 'package:vigia_app/features/reports/domain/entities/nearby_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';

class FakePhotoStorageDataSource implements PhotoStorageDataSource {
  final List<String> calls = [];
  String urlToReturn = 'https://supabase.co/storage/photo.jpg';

  @override
  Future<String> uploadPhoto({
    required Uint8List bytes,
    required String extension,
    required String reporterId,
  }) async {
    calls.add('storage.uploadPhoto');
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

  @override
  Future<IncidentModel> getIncidentById(String idOrTrackingCode) async {
    calls.add('remote.getIncidentById');
    if (lastInserted != null) return lastInserted!;
    throw Exception('No encontrado');
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

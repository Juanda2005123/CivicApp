import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_marker.dart';
import 'package:vigia_app/features/reports/domain/entities/nearby_incident.dart';

import '../models/feed_incident_model.dart';
import '../models/incident_model.dart';

/// Interacts directly with `road_incident`, `incident_photo`, and `incident_upvote` tables.
class IncidentRemoteDataSource {
  final SupabaseClient _client;

  IncidentRemoteDataSource(this._client);

  /// Generates a unique civic tracking code in format #VIG-XXXX.
  static String generateTrackingCode() {
    final rand = Random();
    final number = rand.nextInt(9000) + 1000;
    return '#VIG-$number';
  }

  /// Inserts the incident and stores its photo records. The +100 XP for publishing is
  /// paid by a database trigger (migration 006), never by the app (RN-08).
  Future<IncidentModel> insertIncident({
    required IncidentModel incident,
    required List<String> photoUrls,
  }) async {
    try {
      final insertData = incident.toInsertJson();

      final createdRow = await _client
          .from('road_incident')
          .insert(insertData)
          .select('*, category:incident_category(name, icon), reporter:user_profile!fk_incident_reporter_user(full_name, show_real_name, civic_rank(name))')
          .single();

      final createdIncidentId = createdRow['id_incident'] as String;

      // Insert photos if any
      final List<Map<String, dynamic>> insertedPhotos = [];
      if (photoUrls.isNotEmpty) {
        final photoPayload = photoUrls.asMap().entries.map((entry) {
          return {
            'id_incident': createdIncidentId,
            'file_url': entry.value,
            'is_primary': entry.key == 0,
          };
        }).toList();

        final photosResponse = await _client
            .from('incident_photo')
            .insert(photoPayload)
            .select();
        insertedPhotos.addAll((photosResponse as List<dynamic>).cast<Map<String, dynamic>>());
      }

      final completeJson = Map<String, dynamic>.from(createdRow);
      completeJson['incident_photo'] = insertedPhotos;

      return IncidentModel.fromJson(completeJson);
    } on PostgrestException catch (e) {
      throw Exception('No pudimos publicar el reporte: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error inesperado al guardar el reporte.');
    }
  }

  /// Saves the editable columns of a report (HU-18). The database refuses the
  /// change outside the 30-minute window or with 5 endorsements (RN-03) and its
  /// Spanish message reaches the citizen as it is.
  Future<void> updateIncidentRow({
    required String incidentId,
    required int categoryId,
    required String title,
    required String description,
    required IncidentSeverity severity,
    String? estimatedDimensions,
  }) async {
    try {
      final rows = await _client
          .from('road_incident')
          .update({
            'id_category': categoryId,
            'title': title,
            'description': description,
            'severity': severity.toDbValue(),
            'estimated_dimensions': estimatedDimensions,
          })
          .eq('id_incident', incidentId)
          .select('id_incident');
      if ((rows as List<dynamic>).isEmpty) {
        throw Exception('No pudimos guardar los cambios: el reporte ya no es tuyo o fue retirado.');
      }
    } on PostgrestException catch (e) {
      throw Exception(_serverMessage(e, 'No pudimos guardar los cambios del reporte'));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('No pudimos guardar los cambios del reporte.');
    }
  }

  /// Removes the photo rows [removedPhotoIds] and adds [newPhotoUrls] to a report
  /// (HU-18). When the cover photo goes away, the first one left becomes the cover.
  Future<void> replacePhotos({
    required String incidentId,
    required List<String> removedPhotoIds,
    required List<String> newPhotoUrls,
  }) async {
    try {
      if (removedPhotoIds.isNotEmpty) {
        await _client.from('incident_photo').delete().inFilter('id_photo', removedPhotoIds);
      }
      if (newPhotoUrls.isNotEmpty) {
        await _client.from('incident_photo').insert([
          for (final url in newPhotoUrls) {'id_incident': incidentId, 'file_url': url},
        ]);
      }

      final rows = await _client
          .from('incident_photo')
          .select('id_photo, is_primary')
          .eq('id_incident', incidentId)
          .order('uploaded_at')
          .order('id_photo');
      final photos = (rows as List<dynamic>).cast<Map<String, dynamic>>();
      if (photos.isNotEmpty && !photos.any((photo) => photo['is_primary'] == true)) {
        await _client
            .from('incident_photo')
            .update({'is_primary': true})
            .eq('id_photo', photos.first['id_photo'] as String);
      }
    } on PostgrestException catch (e) {
      throw Exception(_serverMessage(e, 'No pudimos actualizar las fotos'));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('No pudimos actualizar las fotos.');
    }
  }

  /// Deletes a report; its photos, endorsements and comments go with it. The
  /// database refuses it outside the edit window (RN-03) and takes back the 100 XP.
  Future<void> deleteIncident(String incidentId) async {
    try {
      final rows = await _client.from('road_incident').delete().eq('id_incident', incidentId).select('id_incident');
      if ((rows as List<dynamic>).isEmpty) {
        throw Exception('No pudimos eliminar el reporte: ya no es tuyo o fue retirado.');
      }
    } on PostgrestException catch (e) {
      throw Exception(_serverMessage(e, 'No pudimos eliminar el reporte'));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('No pudimos eliminar el reporte.');
    }
  }

  /// A rule the database enforces (`RAISE EXCEPTION`, code P0001) already carries
  /// the message for the citizen; any other failure gets [fallback] in front.
  String _serverMessage(PostgrestException e, String fallback) {
    return e.code == 'P0001' ? e.message : '$fallback: ${e.message}';
  }

  /// Queries active reports within [radiusInMeters] matching [categoryId] for duplicate detection.
  Future<List<NearbyIncident>> getNearbyIncidents({
    required double latitude,
    required double longitude,
    required int categoryId,
    double radiusInMeters = 150.0,
  }) async {
    try {
      // Query active reports of the given category
      final rows = await _client
          .from('road_incident')
          .select('id_incident, id_reporter_user, tracking_code, title, severity, latitude, longitude, incident_category(name), incident_photo(file_url, is_primary), incident_upvote(id_user)')
          .eq('id_category', categoryId)
          .neq('current_status', 'RESOLVED')
          .limit(50);

      final nearbyList = <NearbyIncident>[];

      for (final raw in (rows as List<dynamic>)) {
        final row = raw as Map<String, dynamic>;
        final incLat = (row['latitude'] as num).toDouble();
        final incLng = (row['longitude'] as num).toDouble();

        final distance = _calculateDistanceInMeters(latitude, longitude, incLat, incLng);

        if (distance <= radiusInMeters) {
          final categoryData = row['incident_category'] as Map<String, dynamic>?;
          final photosData = row['incident_photo'] as List<dynamic>?;
          final upvotesData = row['incident_upvote'] as List<dynamic>?;

          String? primaryUrl;
          if (photosData != null && photosData.isNotEmpty) {
            final primaryPhoto = photosData.firstWhere(
              (p) => (p as Map<String, dynamic>)['is_primary'] == true,
              orElse: () => photosData.first,
            ) as Map<String, dynamic>;
            primaryUrl = primaryPhoto['file_url'] as String?;
          }

          nearbyList.add(NearbyIncident(
            id: row['id_incident'] as String,
            trackingCode: row['tracking_code'] as String,
            title: row['title'] as String,
            categoryId: categoryId,
            categoryName: (categoryData?['name'] as String?) ?? 'Incidente vial',
            severity: (row['severity'] as String?) ?? 'MEDIUM',
            distanceInMeters: distance,
            primaryPhotoUrl: primaryUrl,
            upvotesCount: upvotesData?.length ?? 0,
            reporterId: row['id_reporter_user'] as String?,
          ));
        }
      }

      nearbyList.sort((a, b) => a.distanceInMeters.compareTo(b.distanceInMeters));
      return nearbyList;
    } on PostgrestException catch (e) {
      throw Exception('Error al verificar reportes cercanos: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('No pudimos consultar reportes cercanos.');
    }
  }

  /// Reports of [city] for the map, newest first. Capped at [_mapLimit] so a
  /// busy city does not download every row.
  Future<List<IncidentMarker>> getCityIncidents(String city) async {
    try {
      final rows = await _client
          .from('road_incident')
          .select('id_incident, tracking_code, title, description, formatted_address, neighborhood, severity, current_status, latitude, longitude, incident_category(name, icon)')
          .eq('city', city)
          .order('created_at', ascending: false)
          .limit(_mapLimit);

      return (rows as List<dynamic>).map((raw) {
        final row = raw as Map<String, dynamic>;
        final category = row['incident_category'] as Map<String, dynamic>?;
        return IncidentMarker(
          id: row['id_incident'] as String,
          trackingCode: row['tracking_code'] as String,
          title: row['title'] as String,
          categoryName: (category?['name'] as String?) ?? 'Otro daño vial',
          neighborhood: (row['neighborhood'] as String?) ?? '',
          description: (row['description'] as String?) ?? '',
          formattedAddress: (row['formatted_address'] as String?) ?? '',
          categoryIcon: (category?['icon'] as String?) ?? 'more_horiz',
          severity: IncidentSeverity.fromDbValue((row['severity'] as String?) ?? 'MEDIUM'),
          coordinates: Coordinates(
            latitude: (row['latitude'] as num).toDouble(),
            longitude: (row['longitude'] as num).toDouble(),
          ),
          status: IncidentStatus.fromDbValue((row['current_status'] as String?) ?? 'REPORTED'),
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('No pudimos cargar los reportes del mapa: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('No pudimos cargar los reportes del mapa.');
    }
  }

  static const _mapLimit = 200;

  /// One page of the community feed of [city], newest first (HU-19). The id is
  /// a second sort key: reports created at the same instant keep a stable order
  /// between pages, so none is skipped or repeated.
  Future<List<FeedIncident>> getCityFeed(String city, {required int offset, required int limit}) async {
    try {
      final rows = await _client
          .from('road_incident')
          .select(FeedIncidentModel.select)
          .eq('city', city)
          .order('created_at', ascending: false)
          .order('id_incident', ascending: false)
          .range(offset, offset + limit - 1);

      return (rows as List<dynamic>)
          .map((row) => FeedIncidentModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('No pudimos cargar los reportes de la comunidad: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('No pudimos cargar los reportes de la comunidad.');
    }
  }

  /// Fetches full incident detail by ID or tracking code.
  Future<IncidentModel> getIncidentById(String idOrTrackingCode) async {
    try {
      final isTrackingCode = idOrTrackingCode.startsWith('#') ||
          idOrTrackingCode.startsWith('VIG-') ||
          idOrTrackingCode.length < 32;

      var query = _client.from('road_incident').select('''
        *,
        category:incident_category(name, icon),
        reporter:user_profile!fk_incident_reporter_user(full_name, show_real_name, civic_rank(name)),
        incident_photo(*),
        incident_upvote(id_user),
        incident_comment(id_comment)
      ''');

      final row = isTrackingCode
          ? await query.eq('tracking_code', idOrTrackingCode).maybeSingle()
          : await query.eq('id_incident', idOrTrackingCode).maybeSingle();

      if (row == null) {
        throw Exception('El reporte solicitado no existe o fue retirado.');
      }

      return IncidentModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw Exception('No pudimos cargar el reporte: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al consultar el detalle del reporte.');
    }
  }

  /// Registers an upvote for the user on the given incident. An endorsement that
  /// already exists is left as it is (`ignoreDuplicates`), so a double tap or the
  /// "Es este daño" of a report the citizen already backed adds nothing. XP,
  /// the self-vote ban and the validation at 10 votes are database triggers.
  Future<void> endorseIncident({
    required String incidentId,
    required String userId,
  }) async {
    try {
      await _client.from('incident_upvote').upsert(
        {
          'id_incident': incidentId,
          'id_user': userId,
        },
        onConflict: 'id_user,id_incident',
        ignoreDuplicates: true,
      );
    } on PostgrestException catch (e) {
      throw Exception('No pudimos registrar tu apoyo: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al apoyar el reporte.');
    }
  }

  /// Removes the user's upvote from the given incident (HU-15, toggle).
  Future<void> revokeEndorsement({
    required String incidentId,
    required String userId,
  }) async {
    try {
      await _client
          .from('incident_upvote')
          .delete()
          .eq('id_incident', incidentId)
          .eq('id_user', userId);
    } on PostgrestException catch (e) {
      throw Exception('No pudimos retirar tu apoyo: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al retirar el apoyo.');
    }
  }

  /// Great-circle Haversine formula returning distance in meters.
  static double _calculateDistanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180.0;
}

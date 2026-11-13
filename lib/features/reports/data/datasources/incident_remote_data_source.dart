import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vigia_app/features/reports/domain/entities/nearby_incident.dart';

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

  /// Inserts the incident, stores its photo records, and increments citizen XP by +100.
  Future<IncidentModel> insertIncident({
    required IncidentModel incident,
    required List<String> photoUrls,
  }) async {
    try {
      final insertData = incident.toInsertJson();

      final createdRow = await _client
          .from('road_incident')
          .insert(insertData)
          .select('*, category:incident_category(name, icon), reporter:user_profile(full_name, civic_rank(name))')
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

      // Increment reporter XP (+100) per RN-08
      try {
        final profileRow = await _client
            .from('user_profile')
            .select('experience_points')
            .eq('id_user', incident.reporterId)
            .maybeSingle();

        if (profileRow != null) {
          final currentXp = (profileRow['experience_points'] as int?) ?? 0;
          await _client
              .from('user_profile')
              .update({'experience_points': currentXp + 100})
              .eq('id_user', incident.reporterId);
        }
      } catch (_) {
        // Non-blocking for incident publication; XP failure should not discard the published report.
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
          .select('id_incident, tracking_code, title, severity, latitude, longitude, incident_category(name), incident_photo(file_url, is_primary), incident_upvote(id_user)')
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

  /// Fetches full incident detail by ID or tracking code.
  Future<IncidentModel> getIncidentById(String idOrTrackingCode) async {
    try {
      final isCode = idOrTrackingCode.startsWith('#') || idOrTrackingCode.contains('-');

      var query = _client.from('road_incident').select('''
        *,
        category:incident_category(name, icon),
        reporter:user_profile(full_name, civic_rank(name)),
        incident_photo(*),
        incident_upvote(id_user),
        incident_comment(id_comment)
      ''');

      final row = isCode && !idOrTrackingCode.contains('-4') // Check if tracking code format
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

  /// Registers an upvote for the user on the given incident.
  Future<void> endorseIncident({
    required String incidentId,
    required String userId,
  }) async {
    try {
      await _client.from('incident_upvote').upsert({
        'id_incident': incidentId,
        'id_user': userId,
      });
    } on PostgrestException catch (e) {
      throw Exception('No pudimos registrar tu apoyo: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al apoyar el reporte.');
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/geocoded_place.dart';

/// The only class that talks to OpenStreetMap's Nominatim reverse geocoding
/// (HU-26). Usage policy: at most 1 request per second and an identifying
/// User-Agent. A GPS reading or a map point sends up to 6 requests, so this class spaces
/// them by [minInterval].
class NominatimDataSource {
  final http.Client _client;

  /// Gap between two requests; tests pass [Duration.zero].
  final Duration minInterval;

  NominatimDataSource(this._client, {this.minInterval = const Duration(milliseconds: 1100)});

  /// Slower answers are dropped: the citizen keeps typing by hand (HU-26, 3).
  static const timeout = Duration(seconds: 3);

  /// Browsers do not let apps set the User-Agent (and a custom one would make
  /// Nominatim's CORS check fail), so on the web the site's Referer identifies us.
  static const _userAgent = 'VIGIA/1.0 (com.vigia.vigia_app)';

  /// Zoom 18 answers with the nearest building (and its plate, if mapped);
  /// zoom 17 answers with the nearest street and its line.
  static const _buildingZoom = 18;
  static const _streetZoom = 17;

  DateTime? _lastRequestAt;

  Future<GeocodedPlace> reverseGeocode(Coordinates coordinates) => _reverse(coordinates, _buildingZoom);

  Future<GeocodedPlace> streetAt(Coordinates coordinates) => _reverse(coordinates, _streetZoom);

  Future<GeocodedPlace> _reverse(Coordinates coordinates, int zoom) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': '${coordinates.latitude}',
      'lon': '${coordinates.longitude}',
      'zoom': '$zoom',
      'addressdetails': '1',
      'polygon_geojson': '1',
      'accept-language': 'es',
    });

    await _waitForTurn();
    try {
      final response = await _client
          .get(uri, headers: kIsWeb ? null : const {'User-Agent': _userAgent})
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw Exception('No pudimos sugerir la dirección (${response.statusCode}).');
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final address = body['address'];
      if (address is! Map<String, dynamic>) {
        throw Exception('No encontramos una dirección para este punto.');
      }

      return GeocodedPlace(
        road: address['road'] as String?,
        houseNumber: address['house_number'] as String?,
        neighborhood:
            (address['neighbourhood'] ?? address['suburb'] ?? address['quarter']) as String?,
        roadPath: _lineOf(body['geojson']),
      );
    } on TimeoutException {
      throw Exception('La sugerencia de dirección tardó demasiado.');
    } on http.ClientException {
      throw Exception('Sin conexión para sugerir la dirección.');
    } on FormatException {
      throw Exception('No pudimos leer la dirección sugerida.');
    }
  }

  /// Respects the 1 request per second policy across consecutive calls.
  Future<void> _waitForTurn() async {
    final last = _lastRequestAt;
    if (last != null) {
      final wait = minInterval - DateTime.now().difference(last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastRequestAt = DateTime.now();
  }

  /// GeoJSON points are `[longitude, latitude]`. Only a street's line is
  /// useful; a building (Point/Polygon) gives an empty path.
  List<Coordinates> _lineOf(Object? geojson) {
    if (geojson is! Map<String, dynamic>) return const [];
    final coordinates = geojson['coordinates'];
    final List<dynamic>? line = switch (geojson['type']) {
      'LineString' => coordinates as List<dynamic>?,
      'MultiLineString' => (coordinates as List<dynamic>?)?.firstOrNull as List<dynamic>?,
      _ => null,
    };
    if (line == null) return const [];
    return [
      for (final point in line.cast<List<dynamic>>())
        Coordinates(latitude: (point[1] as num).toDouble(), longitude: (point[0] as num).toDouble()),
    ];
  }
}

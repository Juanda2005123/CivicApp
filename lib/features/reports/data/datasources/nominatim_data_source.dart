import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/address_match.dart';
import 'package:vigia_app/features/reports/domain/entities/geocoded_place.dart';

/// The only class that talks to OpenStreetMap's Nominatim: reverse geocoding
/// (HU-26) and the search of a typed address (HU-28). Usage policy: at most 1
/// request per second and an identifying User-Agent. A GPS reading or a map
/// point sends up to 6 requests, so this class spaces them by [minInterval],
/// one after the other even when several callers ask at the same time.
class NominatimDataSource {
  final http.Client _client;

  /// Gap between two requests; tests pass [Duration.zero].
  final Duration minInterval;

  /// The public server is slower for a search than for a reverse lookup, and a
  /// slow answer only means the city center is used (HU-28, criterion 3).
  final Duration searchTimeout;

  NominatimDataSource(
    this._client, {
    this.minInterval = const Duration(milliseconds: 1100),
    this.searchTimeout = const Duration(seconds: 5),
  });

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

  /// Completes when the previous caller has had its turn: callers form a queue.
  Future<void> _previousTurn = Future<void>.value();

  Future<GeocodedPlace> reverseGeocode(Coordinates coordinates) => _reverse(coordinates, _buildingZoom);

  Future<GeocodedPlace> streetAt(Coordinates coordinates) => _reverse(coordinates, _streetZoom);

  /// Result categories that are an area, not an address: a whole city, a
  /// district or a region. They answer "somewhere in Popayán", which is no use
  /// as the point of a report.
  static const _areaCategories = {'boundary', 'place'};

  /// The first street, building or place that matches [query] (HU-28), or null
  /// when there is none. Throws when the service fails, so "not found" and
  /// "could not search" are different answers.
  Future<AddressMatch?> search(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'countrycodes': 'co',
      'limit': '3',
      'accept-language': 'es',
    });

    await _waitForTurn();
    try {
      final response = await _client
          .get(uri, headers: kIsWeb ? null : const {'User-Agent': _userAgent})
          .timeout(searchTimeout);
      if (response.statusCode != 200) {
        throw Exception('No pudimos buscar la dirección (${response.statusCode}).');
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! List) throw const FormatException('Unexpected search answer');
      for (final result in body.whereType<Map<String, dynamic>>()) {
        if (_areaCategories.contains(result['category'])) continue;
        return AddressMatch(
          coordinates: Coordinates(
            latitude: double.parse('${result['lat']}'),
            longitude: double.parse('${result['lon']}'),
          ),
          // A road is only the street; anything else (a house, a shop, a
          // clinic) is a place with its own point.
          isStreetOnly: result['category'] == 'highway',
        );
      }
      return null;
    } on TimeoutException {
      throw Exception('La búsqueda de la dirección tardó demasiado.');
    } on http.ClientException {
      throw Exception('Sin conexión para buscar la dirección.');
    } on FormatException {
      throw Exception('No pudimos leer la respuesta de la búsqueda.');
    }
  }

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

  /// Respects the 1 request per second policy, also across callers that ask at
  /// the same time (the address suggestion and the search of HU-28): each one
  /// waits for the previous one's turn, so two requests never leave together.
  Future<void> _waitForTurn() async {
    final previous = _previousTurn;
    final myTurn = Completer<void>();
    _previousTurn = myTurn.future;
    try {
      await previous;
      final last = _lastRequestAt;
      if (last != null) {
        final wait = minInterval - DateTime.now().difference(last);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }
      _lastRequestAt = DateTime.now();
    } finally {
      myTurn.complete();
    }
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

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/data/datasources/nominatim_data_source.dart';

const _point = Coordinates(latitude: 3.4516, longitude: -76.5320);

http.Response _json(Map<String, dynamic> body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

NominatimDataSource _source(http.Client client) => NominatimDataSource(client, minInterval: Duration.zero);

void main() {
  test('the address asks at building level, in Spanish, and reads road, plate and neighborhood', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return _json({
        'address': {'road': 'Calle 12', 'house_number': '5-37', 'neighbourhood': 'San Pedro'},
        'geojson': {'type': 'Point', 'coordinates': [-76.5318, 3.4513]},
      });
    });

    final place = await _source(client).reverseGeocode(_point);

    expect(place.road, 'Calle 12');
    expect(place.houseNumber, '5-37');
    expect(place.neighborhood, 'San Pedro');
    expect(place.roadPath, isEmpty); // a building is not a street line
    expect(sent.url.host, 'nominatim.openstreetmap.org');
    expect(sent.url.queryParameters['zoom'], '18');
    expect(sent.url.queryParameters['accept-language'], 'es');
    expect(sent.headers['User-Agent'], contains('VIGIA'));
  });

  test('the street asks at street level and reads its line as [lon, lat] pairs', () async {
    late http.Request sent;
    final client = MockClient((request) async {
      sent = request;
      return _json({
        'address': {'road': 'Calle 10A Bis'},
        'geojson': {
          'type': 'LineString',
          'coordinates': [
            [-76.5423, 3.3961],
            [-76.5400, 3.3961],
          ],
        },
      });
    });

    final street = await _source(client).streetAt(_point);

    expect(sent.url.queryParameters['zoom'], '17');
    expect(street.road, 'Calle 10A Bis');
    expect(street.roadPath.map((c) => (c.latitude, c.longitude)), [(3.3961, -76.5423), (3.3961, -76.5400)]);
  });

  test('falls back to the suburb when there is no neighbourhood', () async {
    final client = MockClient((_) async => _json({'address': {'suburb': 'Comuna 3'}}));

    expect((await _source(client).reverseGeocode(_point)).neighborhood, 'Comuna 3');
  });

  test('consecutive requests are spaced to respect 1 request per second', () async {
    final sentAt = <DateTime>[];
    final client = MockClient((_) async {
      sentAt.add(DateTime.now());
      return _json({'address': {'road': 'Calle 12'}});
    });
    final source = NominatimDataSource(client, minInterval: const Duration(milliseconds: 150));

    await source.reverseGeocode(_point);
    await source.streetAt(_point);

    expect(sentAt[1].difference(sentAt[0]), greaterThanOrEqualTo(const Duration(milliseconds: 140)));
  });

  test('a server error becomes a clear exception', () async {
    final client = MockClient((_) async => http.Response('rate limited', 429));

    expect(_source(client).reverseGeocode(_point), throwsA(isA<Exception>()));
  });

  test('a point without address (e.g. the sea) becomes a clear exception', () async {
    final client = MockClient((_) async => _json({'error': 'Unable to geocode'}));

    expect(_source(client).streetAt(_point), throwsA(isA<Exception>()));
  });

  test('no connection becomes a clear exception', () async {
    final client = MockClient((_) async => throw http.ClientException('offline'));

    expect(_source(client).reverseGeocode(_point), throwsA(isA<Exception>()));
  });
}

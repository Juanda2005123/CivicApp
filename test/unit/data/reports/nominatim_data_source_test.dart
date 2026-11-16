import 'dart:async';
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

  group('search (HU-28)', () {
    http.Response list(List<Map<String, dynamic>> body, [int status = 200]) =>
        http.Response.bytes(utf8.encode(jsonEncode(body)), status);

    test('asks in Spanish, only in Colombia, and reads the point of the first result', () async {
      late http.Request sent;
      final client = MockClient((request) async {
        sent = request;
        return list([
          {'category': 'highway', 'type': 'secondary', 'lat': '2.4422653', 'lon': '-76.6091109'},
        ]);
      });

      final point = await _source(client).search('Carrera 9, El Modelo, Popayán, Colombia');

      expect(point.latitude, 2.4422653);
      expect(point.longitude, -76.6091109);
      expect(sent.url.host, 'nominatim.openstreetmap.org');
      expect(sent.url.path, '/search');
      expect(sent.url.queryParameters['q'], 'Carrera 9, El Modelo, Popayán, Colombia');
      expect(sent.url.queryParameters['countrycodes'], 'co');
      expect(sent.url.queryParameters['accept-language'], 'es');
      expect(sent.headers['User-Agent'], contains('VIGIA'));
    });

    test('skips the results that are a whole city or area, and takes the first real one', () async {
      final client = MockClient((_) async => list([
            {'category': 'boundary', 'type': 'administrative', 'lat': '2.4', 'lon': '-76.6'},
            {'category': 'place', 'type': 'suburb', 'lat': '2.5', 'lon': '-76.5'},
            {'category': 'amenity', 'type': 'cafe', 'lat': '2.4422', 'lon': '-76.6091'},
          ]));

      final point = await _source(client).search('Calle 5 # 9-45, Popayán, Colombia');

      expect(point.latitude, 2.4422);
    });

    test('a query that only finds the city (abbreviations!) is "not found", not a point', () async {
      final client = MockClient((_) async => list([
            {'category': 'boundary', 'type': 'administrative', 'lat': '2.4', 'lon': '-76.6'},
          ]));

      await expectLater(
        _source(client).search('Cra 9 # 5-45, Popayán'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('No encontramos esa dirección'))),
      );
    });

    test('no results is "not found"', () async {
      final client = MockClient((_) async => list([]));

      await expectLater(_source(client).search('Avenida 6N # 25-30, Cali'), throwsA(isA<Exception>()));
    });

    test('a server error, no connection and a broken answer become clear exceptions', () async {
      await expectLater(
        _source(MockClient((_) async => http.Response('rate limited', 429))).search('Calle 5, Cali'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('429'))),
      );
      await expectLater(
        _source(MockClient((_) async => throw http.ClientException('offline'))).search('Calle 5, Cali'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Sin conexión'))),
      );
      await expectLater(
        _source(MockClient((_) async => http.Response.bytes(utf8.encode('{"error":"x"}'), 200))).search('Calle 5, Cali'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('No pudimos leer'))),
      );
      await expectLater(
        _source(MockClient((_) async => list([
              {'category': 'highway', 'lat': 'north', 'lon': '-76.6'},
            ]))).search('Calle 5, Cali'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('No pudimos leer'))),
      );
    });

    test('a slow search is dropped after its own, longer, timeout', () async {
      final client = MockClient((_) => Completer<http.Response>().future);
      final source = NominatimDataSource(client, minInterval: Duration.zero, searchTimeout: const Duration(milliseconds: 50));

      await expectLater(
        source.search('Calle 5, Cali'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('tardó demasiado'))),
      );
    });

    test('requests that arrive together leave one after the other, 1 per second apart', () async {
      final sentAt = <DateTime>[];
      final client = MockClient((request) async {
        sentAt.add(DateTime.now());
        if (request.url.path == '/search') {
          return list([
            {'category': 'highway', 'lat': '2.44', 'lon': '-76.6'},
          ]);
        }
        return _json({'address': {'road': 'Calle 12'}});
      });
      final source = NominatimDataSource(client, minInterval: const Duration(milliseconds: 120));

      // The address suggestion (reverse + street) is still running when the
      // citizen confirms the address: all three ask at the same moment.
      await Future.wait([source.reverseGeocode(_point), source.streetAt(_point), source.search('Calle 5, Cali')]);

      expect(sentAt, hasLength(3));
      expect(sentAt[1].difference(sentAt[0]), greaterThanOrEqualTo(const Duration(milliseconds: 110)));
      expect(sentAt[2].difference(sentAt[1]), greaterThanOrEqualTo(const Duration(milliseconds: 110)));
    });

    test('a request that fails does not stall the queue behind it', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        if (calls == 1) throw http.ClientException('offline');
        return list([
          {'category': 'highway', 'lat': '2.44', 'lon': '-76.6'},
        ]);
      });
      final source = _source(client);

      final first = source.search('Calle 5, Cali').then<Object?>((_) => null, onError: (Object e) => e);
      final second = source.search('Calle 5, Cali');

      expect(await first, isA<Exception>());
      expect((await second).latitude, 2.44);
    });
  });
}

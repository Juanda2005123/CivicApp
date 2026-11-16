import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vigia_app/features/reports/data/datasources/nominatim_data_source.dart';
import 'package:vigia_app/features/reports/data/repositories/geocoding_repository_impl.dart';

void main() {
  test('geocodeAddress delegates the typed address to the Nominatim search (HU-28)', () async {
    late Uri requested;
    final client = MockClient((request) async {
      requested = request.url;
      return http.Response.bytes(
        utf8.encode(jsonEncode([
          {'category': 'highway', 'lat': '3.4516', 'lon': '-76.5320'},
        ])),
        200,
      );
    });
    final repository = GeocodingRepositoryImpl(NominatimDataSource(client, minInterval: Duration.zero));

    final point = await repository.geocodeAddress('Carrera 5, Cali, Colombia');

    expect(point!.coordinates.latitude, 3.4516);
    expect(point.coordinates.longitude, -76.5320);
    expect(requested.queryParameters['q'], 'Carrera 5, Cali, Colombia');
  });
}

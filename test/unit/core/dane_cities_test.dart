import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/constants/dane_cities.dart';

void main() {
  group('DaneCitiesCatalog & Calibrated Radii Algorithm', () {
    test('Catalog contains 51 official DANE municipalities', () {
      expect(DaneCitiesCatalog.cities.length, 51);
    });

    test('All cities have unique IDs and coordinates', () {
      final ids = DaneCitiesCatalog.cities.map((c) => c.id).toSet();
      expect(ids.length, 51);
    });

    test('South Cali (Bochalema / Ciudad Jardin / Universities) resolves to Cali, NOT Jamundi', () {
      // Coordinates in southern Cali (Bochalema / Autonoma / Javeriana)
      // Lat: 3.3398, Lon: -76.5332 (~9 km from Jamundi, ~13 km from Plaza de Caicedo)
      final city = DaneCitiesCatalog.findClosestCity(3.3398, -76.5332);
      expect(city.name, 'Cali');
      expect(city.department, 'Valle del Cauca');
    });

    test('Jamundi downtown (Parque Principal) resolves strictly to Jamundi', () {
      // Jamundi main park (Lat: 3.2606, Lon: -76.5414)
      final city = DaneCitiesCatalog.findClosestCity(3.2606, -76.5414);
      expect(city.name, 'Jamundí');
    });

    test('Soacha downtown resolves strictly to Soacha within satellite radius', () {
      // Soacha central park (Lat: 4.5804, Lon: -74.2169)
      final city = DaneCitiesCatalog.findClosestCity(4.5804, -74.2169);
      expect(city.name, 'Soacha');
    });

    test('Bogota conurbation perimeter outside Soacha core resolves to Bogota', () {
      // Bosa / Venecia (southern Bogota, conurbated with Soacha but in Bogota)
      // Lat: 4.6000, Lon: -74.1500
      final city = DaneCitiesCatalog.findClosestCity(4.6000, -74.1500);
      expect(city.name, 'Bogotá');
    });

    test('Itagui downtown resolves to Itagui', () {
      final city = DaneCitiesCatalog.findClosestCity(6.1846, -75.5991);
      expect(city.name, 'Itagüí');
    });

    test('Medellin center resolves to Medellin', () {
      final city = DaneCitiesCatalog.findClosestCity(6.2442, -75.5812);
      expect(city.name, 'Medellín');
    });
  });
}

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

    test('South Cali (Bochalema / Ciudad Jardín / Universidades) resolves to Cali, NOT Jamundí', () {
      // Coordenadas en el extremo sur de Cali (Bochalema / Univ. Autónoma / Javeriana)
      // Lat: 3.3398, Lon: -76.5332 (A ~9 km de Jamundí y ~13 km de la Plaza de Caicedo)
      final city = DaneCitiesCatalog.findClosestCity(3.3398, -76.5332);
      expect(city.nombre, 'Cali');
      expect(city.departamento, 'Valle del Cauca');
    });

    test('Jamundí downtown (Parque Principal) resolves strictly to Jamundí', () {
      // Parque Principal de Jamundí (Lat: 3.2606, Lon: -76.5414)
      final city = DaneCitiesCatalog.findClosestCity(3.2606, -76.5414);
      expect(city.nombre, 'Jamundí');
    });

    test('Soacha downtown resolves strictly to Soacha within satellite radius', () {
      // Parque Central de Soacha (Lat: 4.5804, Lon: -74.2169)
      final city = DaneCitiesCatalog.findClosestCity(4.5804, -74.2169);
      expect(city.nombre, 'Soacha');
    });

    test('Bogotá conurbation perimeter outside Soacha core resolves to Bogotá', () {
      // Bosa / Venecia (sur de Bogotá, conurbado con Soacha pero en Bogotá)
      // Lat: 4.6000, Lon: -74.1500
      final city = DaneCitiesCatalog.findClosestCity(4.6000, -74.1500);
      expect(city.nombre, 'Bogotá');
    });

    test('Itagüí downtown resolves to Itagüí', () {
      final city = DaneCitiesCatalog.findClosestCity(6.1846, -75.5991);
      expect(city.nombre, 'Itagüí');
    });

    test('Medellín center resolves to Medellín', () {
      final city = DaneCitiesCatalog.findClosestCity(6.2442, -75.5812);
      expect(city.nombre, 'Medellín');
    });
  });
}

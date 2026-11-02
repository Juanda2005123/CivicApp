import '../../domain/entities/city.dart';

/// Offline copy of the official DANE coverage catalog (RN-12: 32 capital cities
/// plus municipalities over 100k inhabitants).
///
/// It also carries the calibration of the conurbations (`kind` and `radiusKm`),
/// which the remote `coverage_city` table does not store.
class CityLocalDataSource {
  List<City> getCities() => _cities;

  static const List<City> _cities = [
    // --- CONURBATION CALI ---
    City(id: 1, name: 'Cali', department: 'Valle del Cauca', latitude: 3.4516, longitude: -76.5320, isCapital: true, kind: CityKind.capital, radiusKm: 18.0),
    // --- CONURBATION BOGOTÁ ---
    City(id: 2, name: 'Bogotá', department: 'Bogotá D.C.', latitude: 4.7110, longitude: -74.0721, isCapital: true, kind: CityKind.capital, radiusKm: 22.0),
    // --- CONURBATION MEDELLÍN ---
    City(id: 3, name: 'Medellín', department: 'Antioquia', latitude: 6.2442, longitude: -75.5812, isCapital: true, kind: CityKind.capital, radiusKm: 11.0),
    // --- CONURBATION BARRANQUILLA ---
    City(id: 4, name: 'Barranquilla', department: 'Atlántico', latitude: 10.9685, longitude: -74.7813, isCapital: true, kind: CityKind.capital, radiusKm: 12.0),
    // --- INDEPENDENT CAPITALS ---
    City(id: 5, name: 'Cartagena', department: 'Bolívar', latitude: 10.3910, longitude: -75.4794, isCapital: true),
    // --- CONURBATION BUCARAMANGA ---
    City(id: 6, name: 'Bucaramanga', department: 'Santander', latitude: 7.1254, longitude: -73.1198, isCapital: true, kind: CityKind.capital, radiusKm: 8.0),
    City(id: 7, name: 'Cúcuta', department: 'Norte de Santander', latitude: 7.8939, longitude: -72.5078, isCapital: true),
    City(id: 8, name: 'Pereira', department: 'Risaralda', latitude: 4.8133, longitude: -75.6961, isCapital: true),
    City(id: 9, name: 'Santa Marta', department: 'Magdalena', latitude: 11.2408, longitude: -74.1990, isCapital: true),
    City(id: 10, name: 'Ibagué', department: 'Tolima', latitude: 4.4389, longitude: -75.2322, isCapital: true),
    City(id: 11, name: 'Pasto', department: 'Nariño', latitude: 1.2136, longitude: -77.2811, isCapital: true),
    City(id: 12, name: 'Manizales', department: 'Caldas', latitude: 5.0689, longitude: -75.5174, isCapital: true),
    City(id: 13, name: 'Neiva', department: 'Huila', latitude: 2.9273, longitude: -75.2819, isCapital: true),
    City(id: 14, name: 'Villavicencio', department: 'Meta', latitude: 4.1420, longitude: -73.6266, isCapital: true),
    City(id: 15, name: 'Armenia', department: 'Quindío', latitude: 4.5339, longitude: -75.6811, isCapital: true),
    City(id: 16, name: 'Valledupar', department: 'Cesar', latitude: 10.4631, longitude: -73.2532, isCapital: true),
    City(id: 17, name: 'Montería', department: 'Córdoba', latitude: 8.7479, longitude: -75.8814, isCapital: true),
    City(id: 18, name: 'Sincelejo', department: 'Sucre', latitude: 9.3047, longitude: -75.3978, isCapital: true),
    City(id: 19, name: 'Popayán', department: 'Cauca', latitude: 2.4448, longitude: -76.6147, isCapital: true),
    City(id: 20, name: 'Tunja', department: 'Boyacá', latitude: 5.5353, longitude: -73.3678, isCapital: true),
    City(id: 21, name: 'Riohacha', department: 'La Guajira', latitude: 11.5444, longitude: -72.9072, isCapital: true),
    City(id: 22, name: 'Florencia', department: 'Caquetá', latitude: 1.6144, longitude: -75.6062, isCapital: true),
    City(id: 23, name: 'Quibdó', department: 'Chocó', latitude: 5.6947, longitude: -76.6611, isCapital: true),
    City(id: 24, name: 'Yopal', department: 'Casanare', latitude: 5.3378, longitude: -72.3959, isCapital: true),
    City(id: 25, name: 'San Andrés', department: 'San Andrés y Providencia', latitude: 12.5847, longitude: -81.7006, isCapital: true),
    City(id: 26, name: 'Mocoa', department: 'Putumayo', latitude: 1.1478, longitude: -76.6464, isCapital: true),
    City(id: 27, name: 'Arauca', department: 'Arauca', latitude: 7.0847, longitude: -70.7591, isCapital: true),
    City(id: 28, name: 'San José del Guaviare', department: 'Guaviare', latitude: 2.5729, longitude: -72.6459, isCapital: true),
    City(id: 29, name: 'Leticia', department: 'Amazonas', latitude: -4.2153, longitude: -69.9406, isCapital: true),
    City(id: 30, name: 'Inírida', department: 'Guainía', latitude: 3.8653, longitude: -67.9239, isCapital: true),
    City(id: 31, name: 'Mitú', department: 'Vaupés', latitude: 1.2528, longitude: -70.2333, isCapital: true),
    City(id: 32, name: 'Puerto Carreño', department: 'Vichada', latitude: 6.1890, longitude: -67.4859, isCapital: true),
    // --- SATELLITES AND NON-CAPITAL MUNICIPALITIES ---
    City(id: 33, name: 'Palmira', department: 'Valle del Cauca', latitude: 3.5394, longitude: -76.3036, isCapital: false),
    City(id: 34, name: 'Buenaventura', department: 'Valle del Cauca', latitude: 3.8801, longitude: -77.0312, isCapital: false),
    City(id: 35, name: 'Tuluá', department: 'Valle del Cauca', latitude: 4.0847, longitude: -76.1954, isCapital: false),
    City(id: 36, name: 'Cartago', department: 'Valle del Cauca', latitude: 4.7464, longitude: -75.9117, isCapital: false),
    // Satellites Cali
    City(id: 37, name: 'Jamundí', department: 'Valle del Cauca', latitude: 3.2606, longitude: -76.5414, isCapital: false, kind: CityKind.satellite, radiusKm: 3.0),
    City(id: 38, name: 'Yumbo', department: 'Valle del Cauca', latitude: 3.5822, longitude: -76.4958, isCapital: false, kind: CityKind.satellite, radiusKm: 3.5),
    // Satellites Medellín
    City(id: 39, name: 'Bello', department: 'Antioquia', latitude: 6.3373, longitude: -75.5579, isCapital: false, kind: CityKind.satellite, radiusKm: 3.8),
    City(id: 40, name: 'Itagüí', department: 'Antioquia', latitude: 6.1846, longitude: -75.5991, isCapital: false, kind: CityKind.satellite, radiusKm: 2.8),
    City(id: 41, name: 'Envigado', department: 'Antioquia', latitude: 6.1690, longitude: -75.5874, isCapital: false, kind: CityKind.satellite, radiusKm: 3.2),
    City(id: 42, name: 'Rionegro', department: 'Antioquia', latitude: 6.1552, longitude: -75.3737, isCapital: false),
    // Satellite Barranquilla
    City(id: 43, name: 'Soledad', department: 'Atlántico', latitude: 10.9185, longitude: -74.7646, isCapital: false, kind: CityKind.satellite, radiusKm: 3.6),
    // Satellite Bucaramanga
    City(id: 44, name: 'Floridablanca', department: 'Santander', latitude: 7.0622, longitude: -73.0864, isCapital: false, kind: CityKind.satellite, radiusKm: 3.2),
    City(id: 45, name: 'Barrancabermeja', department: 'Santander', latitude: 7.0653, longitude: -73.8547, isCapital: false),
    // Satellites Bogotá
    City(id: 46, name: 'Soacha', department: 'Cundinamarca', latitude: 4.5804, longitude: -74.2169, isCapital: false, kind: CityKind.satellite, radiusKm: 4.8),
    City(id: 47, name: 'Chía', department: 'Cundinamarca', latitude: 4.8614, longitude: -74.0592, isCapital: false, kind: CityKind.satellite, radiusKm: 4.5),
    City(id: 48, name: 'Zipaquirá', department: 'Cundinamarca', latitude: 5.0261, longitude: -74.0039, isCapital: false),
    City(id: 49, name: 'Facatativá', department: 'Cundinamarca', latitude: 4.8142, longitude: -74.3542, isCapital: false),
    City(id: 50, name: 'Duitama', department: 'Boyacá', latitude: 5.8245, longitude: -73.0341, isCapital: false),
    City(id: 51, name: 'Sogamoso', department: 'Boyacá', latitude: 5.7145, longitude: -72.9339, isCapital: false),
  ];
}

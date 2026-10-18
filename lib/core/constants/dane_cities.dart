import 'dart:math';

/// Representación inmutable de una ciudad de cobertura oficial DANE para VIGÍA.
class DaneCity {
  final int id;
  final String nombre;
  final String departamento;
  final double latitud;
  final double longitud;
  final bool esCapital;

  const DaneCity({
    required this.id,
    required this.nombre,
    required this.departamento,
    required this.latitud,
    required this.longitud,
    required this.esCapital,
  });

  String get displayName => '$nombre ($departamento)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DaneCity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Catálogo canónico de cobertura urbana según RN-12 (32 Capitales + Ciudades > 100k hab).
class DaneCitiesCatalog {
  static const List<DaneCity> cities = [
    DaneCity(id: 1, nombre: 'Cali', departamento: 'Valle del Cauca', latitud: 3.4516, longitud: -76.5320, esCapital: true),
    DaneCity(id: 2, nombre: 'Bogotá', departamento: 'Bogotá D.C.', latitud: 4.7110, longitud: -74.0721, esCapital: true),
    DaneCity(id: 3, nombre: 'Medellín', departamento: 'Antioquia', latitud: 6.2442, longitud: -75.5812, esCapital: true),
    DaneCity(id: 4, nombre: 'Barranquilla', departamento: 'Atlántico', latitud: 10.9685, longitud: -74.7813, esCapital: true),
    DaneCity(id: 5, nombre: 'Cartagena', departamento: 'Bolívar', latitud: 10.3910, longitud: -75.4794, esCapital: true),
    DaneCity(id: 6, nombre: 'Bucaramanga', departamento: 'Santander', latitud: 7.1254, longitud: -73.1198, esCapital: true),
    DaneCity(id: 7, nombre: 'Cúcuta', departamento: 'Norte de Santander', latitud: 7.8939, longitud: -72.5078, esCapital: true),
    DaneCity(id: 8, nombre: 'Pereira', departamento: 'Risaralda', latitud: 4.8133, longitud: -75.6961, esCapital: true),
    DaneCity(id: 9, nombre: 'Santa Marta', departamento: 'Magdalena', latitud: 11.2408, longitud: -74.1990, esCapital: true),
    DaneCity(id: 10, nombre: 'Ibagué', departamento: 'Tolima', latitud: 4.4389, longitud: -75.2322, esCapital: true),
    DaneCity(id: 11, nombre: 'Pasto', departamento: 'Nariño', latitud: 1.2136, longitud: -77.2811, esCapital: true),
    DaneCity(id: 12, nombre: 'Manizales', departamento: 'Caldas', latitud: 5.0689, longitud: -75.5174, esCapital: true),
    DaneCity(id: 13, nombre: 'Neiva', departamento: 'Huila', latitud: 2.9273, longitud: -75.2819, esCapital: true),
    DaneCity(id: 14, nombre: 'Villavicencio', departamento: 'Meta', latitud: 4.1420, longitud: -73.6266, esCapital: true),
    DaneCity(id: 15, nombre: 'Armenia', departamento: 'Quindío', latitud: 4.5339, longitud: -75.6811, esCapital: true),
    DaneCity(id: 16, nombre: 'Valledupar', departamento: 'Cesar', latitud: 10.4631, longitud: -73.2532, esCapital: true),
    DaneCity(id: 17, nombre: 'Montería', departamento: 'Córdoba', latitud: 8.7479, longitud: -75.8814, esCapital: true),
    DaneCity(id: 18, nombre: 'Sincelejo', departamento: 'Sucre', latitud: 9.3047, longitud: -75.3978, esCapital: true),
    DaneCity(id: 19, nombre: 'Popayán', departamento: 'Cauca', latitud: 2.4448, longitud: -76.6147, esCapital: true),
    DaneCity(id: 20, nombre: 'Tunja', departamento: 'Boyacá', latitud: 5.5353, longitud: -73.3678, esCapital: true),
    DaneCity(id: 21, nombre: 'Riohacha', departamento: 'La Guajira', latitud: 11.5444, longitud: -72.9072, esCapital: true),
    DaneCity(id: 22, nombre: 'Florencia', departamento: 'Caquetá', latitud: 1.6144, longitud: -75.6062, esCapital: true),
    DaneCity(id: 23, nombre: 'Quibdó', departamento: 'Chocó', latitud: 5.6947, longitud: -76.6611, esCapital: true),
    DaneCity(id: 24, nombre: 'Yopal', departamento: 'Casanare', latitud: 5.3378, longitud: -72.3959, esCapital: true),
    DaneCity(id: 25, nombre: 'San Andrés', departamento: 'San Andrés y Providencia', latitud: 12.5847, longitud: -81.7006, esCapital: true),
    DaneCity(id: 26, nombre: 'Mocoa', departamento: 'Putumayo', latitud: 1.1478, longitud: -76.6464, esCapital: true),
    DaneCity(id: 27, nombre: 'Arauca', departamento: 'Arauca', latitud: 7.0847, longitud: -70.7591, esCapital: true),
    DaneCity(id: 28, nombre: 'San José del Guaviare', departamento: 'Guaviare', latitud: 2.5729, longitud: -72.6459, esCapital: true),
    DaneCity(id: 29, nombre: 'Leticia', departamento: 'Amazonas', latitud: -4.2153, longitud: -69.9406, esCapital: true),
    DaneCity(id: 30, nombre: 'Inírida', departamento: 'Guainía', latitud: 3.8653, longitud: -67.9239, esCapital: true),
    DaneCity(id: 31, nombre: 'Mitú', departamento: 'Vaupés', latitud: 1.2528, longitud: -70.2333, esCapital: true),
    DaneCity(id: 32, nombre: 'Puerto Carreño', departamento: 'Vichada', latitud: 6.1890, longitud: -67.4859, esCapital: true),
    // Municipios no capitales > 100k hab / Áreas Metropolitanas
    DaneCity(id: 33, nombre: 'Palmira', departamento: 'Valle del Cauca', latitud: 3.5394, longitud: -76.3036, esCapital: false),
    DaneCity(id: 34, nombre: 'Buenaventura', departamento: 'Valle del Cauca', latitud: 3.8801, longitud: -77.0312, esCapital: false),
    DaneCity(id: 35, nombre: 'Tuluá', departamento: 'Valle del Cauca', latitud: 4.0847, longitud: -76.1954, esCapital: false),
    DaneCity(id: 36, nombre: 'Cartago', departamento: 'Valle del Cauca', latitud: 4.7464, longitud: -75.9117, esCapital: false),
    DaneCity(id: 37, nombre: 'Jamundí', departamento: 'Valle del Cauca', latitud: 3.2606, longitud: -76.5414, esCapital: false),
    DaneCity(id: 38, nombre: 'Yumbo', departamento: 'Valle del Cauca', latitud: 3.5822, longitud: -76.4958, esCapital: false),
    DaneCity(id: 39, nombre: 'Bello', departamento: 'Antioquia', latitud: 6.3373, longitud: -75.5579, esCapital: false),
    DaneCity(id: 40, nombre: 'Itagüí', departamento: 'Antioquia', latitud: 6.1846, longitud: -75.5991, esCapital: false),
    DaneCity(id: 41, nombre: 'Envigado', departamento: 'Antioquia', latitud: 6.1690, longitud: -75.5874, esCapital: false),
    DaneCity(id: 42, nombre: 'Rionegro', departamento: 'Antioquia', latitud: 6.1552, longitud: -75.3737, esCapital: false),
    DaneCity(id: 43, nombre: 'Soledad', departamento: 'Atlántico', latitud: 10.9185, longitud: -74.7646, esCapital: false),
    DaneCity(id: 44, nombre: 'Floridablanca', departamento: 'Santander', latitud: 7.0622, longitud: -73.0864, esCapital: false),
    DaneCity(id: 45, nombre: 'Barrancabermeja', departamento: 'Santander', latitud: 7.0653, longitud: -73.8547, esCapital: false),
    DaneCity(id: 46, nombre: 'Soacha', departamento: 'Cundinamarca', latitud: 4.5804, longitud: -74.2169, esCapital: false),
    DaneCity(id: 47, nombre: 'Chía', departamento: 'Cundinamarca', latitud: 4.8614, longitud: -74.0592, esCapital: false),
    DaneCity(id: 48, nombre: 'Zipaquirá', departamento: 'Cundinamarca', latitud: 5.0261, longitud: -74.0039, esCapital: false),
    DaneCity(id: 49, nombre: 'Facatativá', departamento: 'Cundinamarca', latitud: 4.8142, longitud: -74.3542, esCapital: false),
    DaneCity(id: 50, nombre: 'Duitama', departamento: 'Boyacá', latitud: 5.8245, longitud: -73.0341, esCapital: false),
    DaneCity(id: 51, nombre: 'Sogamoso', departamento: 'Boyacá', latitud: 5.7145, longitud: -72.9339, esCapital: false),
  ];

  /// Calcula la distancia euclidiana aproximada en km (Fórmula de Haversine)
  /// para encontrar la ciudad del catálogo más cercana a las coordenadas GPS del ciudadano.
  static DaneCity findClosestCity(double lat, double lng) {
    DaneCity closest = cities.first;
    double minDistance = double.infinity;

    for (final city in cities) {
      final distance = _calculateDistanceKm(lat, lng, city.latitud, city.longitud);
      if (distance < minDistance) {
        minDistance = distance;
        closest = city;
      }
    }
    return closest;
  }

  static double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}

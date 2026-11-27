import '../../../domain/entities/city_copy.dart';
import '../../../domain/entities/city_identity.dart';
import '../../../domain/entities/city_palette.dart';
import '../../../domain/entities/city_photo.dart';
import '../../../domain/entities/day_part.dart';
import '../../../domain/entities/landmark.dart';

// Medellín. Values from the approved mockup,
// docs/design/mockups/city-identity.html (PACKS).
const String _assets = 'assets/cities/medellin';

const CityIdentity medellinPack = CityIdentity(
  slug: 'medellin',
  name: 'Medellín',
  department: 'Antioquia',
  level: CityIdentityLevel.full,
  palette: CityPalette(
    deep: 0xFF0E6B3F, // flag green
    accent: 0xFFF4B400, // silleta
    onAccent: 0xFF1A1400,
    veil: 0xFF0B2A1E,
    // Flag, top to bottom.
    flag: [
      FlagBand(0xFFFFFFFF, 1),
      FlagBand(0xFF0E6B3F, 1),
    ],
  ),
  heroes: {
    DayPart.morning: CityPhoto('$_assets/hero_morning.webp', 'Medellín desde el cerro El Picacho'),
    DayPart.afternoon: CityPhoto('$_assets/hero_afternoon.webp', 'Metrocable sobre la Comuna 1'),
    DayPart.night: CityPhoto('$_assets/hero_night.webp', 'Medellín de noche'),
  },
  // From the lowest rank (0 XP) to the highest (4.000 XP).
  landmarks: [
    Landmark(
      rankName: 'Observador Urbano',
      title: 'Comuna 13',
      photo: CityPhoto('$_assets/rank_1.webp', 'Grafitis de la Comuna 13'),
    ),
    Landmark(
      rankName: 'Vecino Activo',
      title: 'Plaza Botero',
      photo: CityPhoto('$_assets/rank_2.webp', 'Esculturas en la Plaza Botero'),
    ),
    Landmark(
      rankName: 'Guardián Vial',
      title: 'Metrocable',
      photo: CityPhoto('$_assets/rank_3.webp', 'Cabina del Metrocable'),
    ),
    Landmark(
      rankName: 'Veedor Mayor',
      title: 'Pueblito Paisa',
      photo: CityPhoto('$_assets/rank_4.webp', 'Pueblito Paisa en el cerro Nutibara'),
    ),
  ],
  copy: CityCopy(
    morningGreeting: '¡Buenos días, parce!',
    afternoonGreeting: '¡Quiubo, parce!',
    nightGreeting: '¡Buenas noches, parce!',
    slogan: 'Medellín se cuida entre vecinos.',
    validationCheer: '¡Qué chimba, parce!',
    climbTitle: 'Tu subida al Pueblito Paisa',
  ),
);

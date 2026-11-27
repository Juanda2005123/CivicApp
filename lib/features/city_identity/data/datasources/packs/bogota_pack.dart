import '../../../domain/entities/city_copy.dart';
import '../../../domain/entities/city_identity.dart';
import '../../../domain/entities/city_palette.dart';
import '../../../domain/entities/city_photo.dart';
import '../../../domain/entities/day_part.dart';
import '../../../domain/entities/landmark.dart';

// Bogotá D.C. The values come from the approved mockup,
// docs/design/mockups/city-identity.html (PACKS).
const String _assets = 'assets/cities/bogota';

const CityIdentity bogotaPack = CityIdentity(
  slug: 'bogota',
  name: 'Bogotá',
  department: 'Bogotá D.C.',
  level: CityIdentityLevel.full,
  palette: CityPalette(
    deep: 0xFF8C2F1B, // brick of the city's architecture
    accent: 0xFFF6C21C, // yellow of the flag
    onAccent: 0xFF1A1300,
    veil: 0xFF14202E,
    // Flag, top to bottom: two halves, without the coat of arms.
    flag: [
      FlagBand(0xFFFCDD09, 1),
      FlagBand(0xFFDA121A, 1),
    ],
  ),
  heroes: {
    DayPart.morning: CityPhoto('$_assets/hero_morning.webp', 'El centro de Bogotá y los cerros orientales'),
    DayPart.afternoon: CityPhoto('$_assets/hero_afternoon.webp', 'El centro de Bogotá con el sol de la tarde'),
    DayPart.night: CityPhoto('$_assets/hero_night.webp', 'Bogotá de noche'),
  },
  // From the lowest rank (0 XP) to the highest (4.000 XP).
  landmarks: [
    Landmark(
      rankName: 'Observador Urbano',
      title: 'Chorro de Quevedo',
      photo: CityPhoto('$_assets/rank_1.webp', 'Plaza del Chorro de Quevedo'),
    ),
    Landmark(
      rankName: 'Vecino Activo',
      title: 'Plaza de Bolívar',
      photo: CityPhoto('$_assets/rank_2.webp', 'La Catedral en la Plaza de Bolívar'),
    ),
    Landmark(
      rankName: 'Guardián Vial',
      title: 'Torre Colpatria',
      photo: CityPhoto('$_assets/rank_3.webp', 'Torre Colpatria'),
    ),
    Landmark(
      rankName: 'Veedor Mayor',
      title: 'Monserrate',
      photo: CityPhoto('$_assets/rank_4.webp', 'Santuario de Monserrate'),
    ),
  ],
  copy: CityCopy(
    morningGreeting: '¡Buenos días, sumercé!',
    afternoonGreeting: '¡Qué más, sumercé!',
    nightGreeting: '¡Buenas noches, sumercé!',
    slogan: 'Bogotá se cuida entre vecinos.',
    validationCheer: '¡Qué bacano!',
    climbTitle: 'Tu subida a Monserrate',
  ),
);

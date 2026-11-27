import '../../../domain/entities/city_copy.dart';
import '../../../domain/entities/city_identity.dart';
import '../../../domain/entities/city_palette.dart';
import '../../../domain/entities/city_photo.dart';
import '../../../domain/entities/day_part.dart';
import '../../../domain/entities/landmark.dart';

// Cartagena de Indias. The values come from the approved mockup,
// docs/design/mockups/city-identity.html (PACKS).
const String _assets = 'assets/cities/cartagena';

const CityIdentity cartagenaPack = CityIdentity(
  slug: 'cartagena',
  name: 'Cartagena',
  department: 'Bolívar',
  level: CityIdentityLevel.full,
  palette: CityPalette(
    deep: 0xFF8A2258, // bougainvillea of the walled city
    accent: 0xFFFF9470, // coral
    onAccent: 0xFF2A0F06,
    veil: 0xFF102235,
    // Flag, top to bottom: its three nested rectangles read as bands, without the star.
    flag: [
      FlagBand(0xFFDD0000, 1),
      FlagBand(0xFFFFEE00, 1),
      FlagBand(0xFF008F4C, 2),
      FlagBand(0xFFFFEE00, 1),
      FlagBand(0xFFDD0000, 1),
    ],
  ),
  heroes: {
    DayPart.morning: CityPhoto('$_assets/hero_morning.webp', 'Bocagrande desde el mar'),
    DayPart.afternoon: CityPhoto('$_assets/hero_afternoon.webp', 'Atardecer desde una garita de las murallas'),
    DayPart.night: CityPhoto('$_assets/hero_night.webp', 'Cartagena y su bahía al anochecer'),
  },
  // From the lowest rank (0 XP) to the highest (4.000 XP).
  landmarks: [
    Landmark(
      rankName: 'Observador Urbano',
      title: 'Torre del Reloj',
      photo: CityPhoto('$_assets/rank_1.webp', 'Torre del Reloj'),
    ),
    Landmark(
      rankName: 'Vecino Activo',
      title: 'Las Murallas',
      photo: CityPhoto('$_assets/rank_2.webp', 'Un baluarte de las murallas'),
    ),
    Landmark(
      rankName: 'Guardián Vial',
      title: 'Castillo San Felipe',
      photo: CityPhoto('$_assets/rank_3.webp', 'Castillo San Felipe de Barajas'),
    ),
    Landmark(
      rankName: 'Veedor Mayor',
      title: 'La Popa',
      photo: CityPhoto('$_assets/rank_4.webp', 'Claustro del convento de La Popa'),
    ),
  ],
  copy: CityCopy(
    morningGreeting: '¡Buenos días, mi llave!',
    afternoonGreeting: '¡Ajá, mi llave!',
    nightGreeting: '¡Buenas noches, mi llave!',
    slogan: 'Cartagena se cuida entre vecinos.',
    validationCheer: '¡Qué nota!',
    climbTitle: 'Tu subida al Cerro de La Popa',
  ),
);

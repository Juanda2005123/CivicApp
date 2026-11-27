import '../../../domain/entities/city_copy.dart';
import '../../../domain/entities/city_identity.dart';
import '../../../domain/entities/city_palette.dart';
import '../../../domain/entities/city_photo.dart';
import '../../../domain/entities/day_part.dart';
import '../../../domain/entities/landmark.dart';

// Santiago de Cali. To add a city, copy this file and change only the data
// (docs/design/05-new-city-guide.md). The values come from the approved mockup,
// docs/design/mockups/city-identity.html (PACKS).
const String _assets = 'assets/cities/cali';

const CityIdentity caliPack = CityIdentity(
  slug: 'cali',
  name: 'Cali',
  department: 'Valle del Cauca',
  level: CityIdentityLevel.full,
  palette: CityPalette(
    deep: 0xFF1B4B5F, // petrol blue
    accent: 0xFFF08A24, // sun of the Farallones
    onAccent: 0xFF1B1205,
    veil: 0xFF0B2433,
    // Flag, top to bottom (to be confirmed with the Alcaldía).
    flag: [
      FlagBand(0xFF1D3E9E, 3),
      FlagBand(0xFFC8202F, 1),
      FlagBand(0xFFFFFFFF, 3),
      FlagBand(0xFFC8202F, 1),
      FlagBand(0xFF1C7C43, 3),
    ],
  ),
  heroes: {
    DayPart.morning: CityPhoto('$_assets/hero_morning.webp', 'Centro de Cali desde Cristo Rey'),
    DayPart.afternoon: CityPhoto('$_assets/hero_afternoon.webp', 'Cerro de las Tres Cruces'),
    DayPart.night: CityPhoto('$_assets/hero_night.webp', 'El oeste de Cali de noche'),
  },
  // From the lowest rank (0 XP) to the highest (4.000 XP).
  landmarks: [
    Landmark(
      rankName: 'Observador Urbano',
      title: 'Gato del Río',
      photo: CityPhoto('$_assets/rank_1.webp', 'Gato del Río'),
    ),
    Landmark(
      rankName: 'Vecino Activo',
      title: 'La Ermita',
      photo: CityPhoto('$_assets/rank_2.webp', 'Iglesia La Ermita'),
    ),
    Landmark(
      rankName: 'Guardián Vial',
      title: 'Cristo Rey',
      photo: CityPhoto('$_assets/rank_3.webp', 'Monumento a Cristo Rey'),
    ),
    Landmark(
      rankName: 'Veedor Mayor',
      title: 'Cerro de las Tres Cruces',
      photo: CityPhoto('$_assets/rank_4.webp', 'Las cruces del Cerro de las Tres Cruces'),
    ),
  ],
  copy: CityCopy(
    morningGreeting: '¡Buenos días, ve!',
    afternoonGreeting: '¡Qué más, ve!',
    nightGreeting: '¡Buenas noches, ve!',
    slogan: 'Cali se cuida entre vecinos.',
    validationCheer: '¡Eso, ve!',
    climbTitle: 'Tu subida al Cerro de las Tres Cruces',
  ),
);

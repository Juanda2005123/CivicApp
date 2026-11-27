import '../../../domain/entities/city_copy.dart';
import '../../../domain/entities/city_identity.dart';
import '../../../domain/entities/city_palette.dart';
import '../../../domain/entities/landmark.dart';

/// The app without a city: the "Sello comunitario" system as it is. No photos
/// and no flag; the theme keeps its own colors for a fallback look, so the
/// palette only feeds the pieces that are always drawn (mustard and ink).
const CityIdentity defaultPack = CityIdentity(
  slug: 'default',
  level: CityIdentityLevel.fallback,
  palette: CityPalette(
    deep: 0xFF10364A, // ink
    accent: 0xFFE8B03A, // mustard
    onAccent: 0xFF0B2433,
    veil: 0xFF0B2433,
  ),
  landmarks: [
    Landmark(rankName: 'Observador Urbano', title: 'Observador Urbano'),
    Landmark(rankName: 'Vecino Activo', title: 'Vecino Activo'),
    Landmark(rankName: 'Guardián Vial', title: 'Guardián Vial'),
    Landmark(rankName: 'Veedor Mayor', title: 'Veedor Mayor'),
  ],
  copy: CityCopy(
    morningGreeting: 'Buenos días',
    afternoonGreeting: 'Buenas tardes',
    nightGreeting: 'Buenas noches',
    slogan: 'Tu ciudad se cuida entre vecinos.',
    validationCheer: '¡Reporte validado!',
    climbTitle: 'Tu subida cívica',
  ),
);

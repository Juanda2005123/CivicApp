import 'package:equatable/equatable.dart';

import 'city_copy.dart';
import 'city_palette.dart';
import 'city_photo.dart';
import 'day_part.dart';
import 'landmark.dart';

/// How much of its own look a city has.
enum CityIdentityLevel {
  /// Its own pack: palette, flag, photos, places and words.
  full,

  /// The pack of its region (the "generic city").
  regional,

  /// No pack: the app looks like the "Sello comunitario" system.
  fallback,
}

/// Everything that changes from one city to another. A city is **data**: no
/// screen or widget ever asks which city it is drawing
/// (docs/design/04-city-identity.md).
class CityIdentity extends Equatable {
  /// Folder of its assets and name of its pack ("cali").
  final String slug;

  /// City and department as the citizen reads them. Empty in a pack that serves
  /// many cities until the use case fills them in.
  final String name;
  final String department;

  final CityIdentityLevel level;
  final CityPalette palette;

  /// Header photo of each moment of the day; empty in the looks without photos.
  final Map<DayPart, CityPhoto> heroes;

  /// The four places of the civic ranks, from the lowest rank to the highest.
  final List<Landmark> landmarks;

  final CityCopy copy;

  const CityIdentity({
    required this.slug,
    this.name = '',
    this.department = '',
    required this.level,
    required this.palette,
    this.heroes = const {},
    required this.landmarks,
    required this.copy,
  });

  /// The same pack dressed for the citizen's city.
  CityIdentity forCity(String cityName, String cityDepartment) => CityIdentity(
        slug: slug,
        name: cityName,
        department: cityDepartment,
        level: level,
        palette: palette,
        heroes: heroes,
        landmarks: landmarks,
        copy: copy.forCity(cityName),
      );

  @override
  List<Object?> get props => [slug, name, department, level, palette, heroes, landmarks, copy];
}

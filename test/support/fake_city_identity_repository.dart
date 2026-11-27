import 'package:vigia_app/features/city_identity/domain/entities/city_copy.dart';
import 'package:vigia_app/features/city_identity/domain/entities/city_identity.dart';
import 'package:vigia_app/features/city_identity/domain/entities/city_palette.dart';
import 'package:vigia_app/features/city_identity/domain/entities/city_ref.dart';
import 'package:vigia_app/features/city_identity/domain/entities/landmark.dart';
import 'package:vigia_app/features/city_identity/domain/repositories/city_identity_repository.dart';

/// A pack with no photos, enough for the domain and Bloc tests.
CityIdentity samplePack(
  String slug, {
  String name = '',
  String department = '',
  CityIdentityLevel level = CityIdentityLevel.full,
  String slogan = 'Aquí nos cuidamos.',
}) {
  return CityIdentity(
    slug: slug,
    name: name,
    department: department,
    level: level,
    palette: const CityPalette(deep: 0xFF000000, accent: 0xFFFFFFFF, onAccent: 0xFF000000, veil: 0xFF000000),
    landmarks: const [Landmark(rankName: 'Observador Urbano', title: 'Observador Urbano')],
    copy: CityCopy(
      morningGreeting: 'Buenos días',
      afternoonGreeting: 'Buenas tardes',
      nightGreeting: 'Buenas noches',
      slogan: slogan,
      validationCheer: '¡Listo!',
      climbTitle: 'Tu subida',
    ),
  );
}

/// In-memory [CityIdentityRepository] with exact matching, that records what is
/// saved.
class FakeCityIdentityRepository implements CityIdentityRepository {
  final List<CityIdentity> fullPacks;
  final Map<String, CityIdentity> regionalByDepartment;
  CityRef? lastCity;
  Exception? readError;
  Exception? saveError;
  final List<CityRef> saved = [];

  FakeCityIdentityRepository({
    this.fullPacks = const [],
    this.regionalByDepartment = const {},
    this.lastCity,
  });

  @override
  CityIdentity? findFullPack(String cityName, {String? department}) {
    for (final pack in fullPacks) {
      if (pack.name == cityName && (department == null || pack.department == department)) return pack;
    }
    return null;
  }

  @override
  CityIdentity? findRegionalPack(String department) => regionalByDepartment[department];

  @override
  CityIdentity getDefaultPack() => samplePack('default', level: CityIdentityLevel.fallback);

  @override
  List<CityIdentity> getFullPacks() => fullPacks;

  @override
  Future<CityRef?> readLastCity() async {
    if (readError != null) throw readError!;
    return lastCity;
  }

  @override
  Future<void> saveLastCity(CityRef city) async {
    if (saveError != null) throw saveError!;
    saved.add(city);
    lastCity = city;
  }
}

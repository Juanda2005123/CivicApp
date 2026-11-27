import '../../../../core/utils/search_text.dart';
import '../../domain/entities/city_identity.dart';
import 'packs/bogota_pack.dart';
import 'packs/cali_pack.dart';
import 'packs/default_pack.dart';
import 'packs/medellin_pack.dart';
import 'packs/regional_packs.dart';

/// The registry of the city packs bundled with the app. No network: a pack is
/// constant data plus the photos in `assets/cities/`.
class CityPackLocalDataSource {
  /// Register a new city here, in the order it is shown.
  static const List<CityIdentity> _fullPacks = [
    caliPack,
    medellinPack,
    bogotaPack,
  ];

  List<CityIdentity> getFullPacks() => _fullPacks;

  CityIdentity getDefaultPack() => defaultPack;

  /// Accents and capitals do not matter ("medellin" finds "Medellín").
  CityIdentity? findFullPack(String cityName, {String? department}) {
    final name = normalizeSearchText(cityName.trim());
    final region = department == null ? null : normalizeSearchText(department.trim());

    for (final pack in _fullPacks) {
      if (normalizeSearchText(pack.name) != name) continue;
      if (region == null || normalizeSearchText(pack.department) == region) return pack;
    }
    return null;
  }

  CityIdentity? findRegionalPack(String department) {
    final region = regionOfDepartment(department);
    return region == null ? null : regionalPacks[region];
  }
}

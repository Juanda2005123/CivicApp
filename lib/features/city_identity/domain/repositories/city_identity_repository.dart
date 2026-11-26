import '../entities/city_identity.dart';
import '../entities/city_ref.dart';

/// The city packs bundled with the app, and the last city it dressed for.
/// Everything is local: no network and nothing in the database.
abstract class CityIdentityRepository {
  /// The full pack of [cityName], or null. [department] tells apart cities that
  /// share a name; without it only the name counts.
  CityIdentity? findFullPack(String cityName, {String? department});

  /// The pack of the region [department] belongs to, or null while that region
  /// has no design.
  CityIdentity? findRegionalPack(String department);

  /// The look of the app when a city has no pack: "Sello comunitario".
  CityIdentity getDefaultPack();

  /// The cities with their own pack, in the order they are shown.
  List<CityIdentity> getFullPacks();

  Future<CityRef?> readLastCity();

  Future<void> saveLastCity(CityRef city);
}

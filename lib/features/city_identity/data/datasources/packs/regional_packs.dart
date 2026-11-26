import '../../../../../core/utils/search_text.dart';
import '../../../domain/entities/city_identity.dart';

/// Regions of the "generic city": one pack per region, not per city
/// (docs/design/04-city-identity.md, section 3.4).
enum ColombianRegion { caribe, pacifico, andina, llanos, amazonia, insular }

/// The region of every department of the DANE catalog, without accents.
/// Cali (Valle del Cauca), Bogotá, Medellín and Cartagena have their own pack,
/// which wins over the region.
const Map<String, ColombianRegion> _regionOfDepartment = {
  'atlantico': ColombianRegion.caribe,
  'bolivar': ColombianRegion.caribe,
  'cesar': ColombianRegion.caribe,
  'cordoba': ColombianRegion.caribe,
  'la guajira': ColombianRegion.caribe,
  'magdalena': ColombianRegion.caribe,
  'sucre': ColombianRegion.caribe,
  'cauca': ColombianRegion.pacifico,
  'choco': ColombianRegion.pacifico,
  'narino': ColombianRegion.pacifico,
  'valle del cauca': ColombianRegion.pacifico,
  'antioquia': ColombianRegion.andina,
  'bogota d.c.': ColombianRegion.andina,
  'boyaca': ColombianRegion.andina,
  'caldas': ColombianRegion.andina,
  'cundinamarca': ColombianRegion.andina,
  'huila': ColombianRegion.andina,
  'norte de santander': ColombianRegion.andina,
  'quindio': ColombianRegion.andina,
  'risaralda': ColombianRegion.andina,
  'santander': ColombianRegion.andina,
  'tolima': ColombianRegion.andina,
  'arauca': ColombianRegion.llanos,
  'casanare': ColombianRegion.llanos,
  'meta': ColombianRegion.llanos,
  'vichada': ColombianRegion.llanos,
  'amazonas': ColombianRegion.amazonia,
  'caqueta': ColombianRegion.amazonia,
  'guainia': ColombianRegion.amazonia,
  'guaviare': ColombianRegion.amazonia,
  'putumayo': ColombianRegion.amazonia,
  'vaupes': ColombianRegion.amazonia,
  'san andres y providencia': ColombianRegion.insular,
};

ColombianRegion? regionOfDepartment(String department) =>
    _regionOfDepartment[normalizeSearchText(department.trim())];

/// Empty until someone designs the regions (guide, section 5): those cities
/// look like the default pack meanwhile. A regional pack is a `CityIdentity`
/// with `level: CityIdentityLevel.regional`, no name, the Colombian flag
/// (yellow 2, blue 1, red 1), the generic rank names and
/// `slogan: '{ciudad} se cuida entre vecinos.'`.
const Map<ColombianRegion, CityIdentity> regionalPacks = {};

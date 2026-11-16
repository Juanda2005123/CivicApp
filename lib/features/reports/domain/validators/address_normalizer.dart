/// Turns the address a citizen writes into the words the geocoding service
/// reads (HU-28).
///
/// OpenStreetMap names streets in full ("Carrera 9", "Avenida 6 Norte") but
/// people write them short ("Cra 9", "Av 6N", "No." for "#"). With an
/// abbreviation the service finds only the whole city, so the address is
/// rewritten before the search. A tested sample:
///
/// | typed | the service finds |
/// |---|---|
/// | `Cra 9 # 5-45` | the city only (useless) |
/// | `Carrera 9 # 5-45` | the street, or the building when its number is mapped |
/// | `Avenida 6N # 25-30` | nothing |
/// | `Avenida 6 Norte # 25-30` | the avenue |
class AddressNormalizer {
  /// Road types and their usual abbreviations, lower case, no dot.
  static const Map<String, String> _roadTypes = {
    'carrera': 'Carrera',
    'cra': 'Carrera',
    'cr': 'Carrera',
    'kr': 'Carrera',
    'kra': 'Carrera',
    'carr': 'Carrera',
    'calle': 'Calle',
    'cl': 'Calle',
    'cll': 'Calle',
    'cal': 'Calle',
    'clle': 'Calle',
    'avenida': 'Avenida',
    'av': 'Avenida',
    'avda': 'Avenida',
    'ave': 'Avenida',
    'ak': 'Avenida Carrera',
    'ac': 'Avenida Calle',
    'diagonal': 'Diagonal',
    'diag': 'Diagonal',
    'dg': 'Diagonal',
    'dig': 'Diagonal',
    'transversal': 'Transversal',
    'trans': 'Transversal',
    'transv': 'Transversal',
    'tv': 'Transversal',
    'circular': 'Circular',
    'cir': 'Circular',
    'circ': 'Circular',
    'autopista': 'Autopista',
    'aut': 'Autopista',
    'autop': 'Autopista',
  };

  static const Map<String, String> _directions = {
    'n': 'Norte',
    'norte': 'Norte',
    's': 'Sur',
    'sur': 'Sur',
    'e': 'Este',
    'este': 'Este',
    'o': 'Oeste',
    'oeste': 'Oeste',
  };

  /// "5", "10A", "6N", "6 Norte", "10 Bis", "12A Bis Sur": a number, an optional
  /// letter (never N, S, E or O: those are directions), an optional "Bis" and
  /// an optional direction.
  static final RegExp _numberPattern = RegExp(
    r'^(\d+)\s*([A-DF-MP-RT-Za-df-mp-rt-z])?\s*(bis)?\s*(norte|sur|este|oeste|n|s|e|o)?$',
    caseSensitive: false,
  );

  /// "No.", "Nº", "N°" and "Nro." before a number mean "#".
  static final RegExp _numberMark = RegExp(r'(?<=\s)(?:n[°º]|nro\.?|no\.?)\s*(?=\d)', caseSensitive: false);

  /// The address split in the parts of the Colombian nomenclature, or null when
  /// it is not one ("Frente a la estación Bellavista"): `Carrera 9 # 5-45` is
  /// road `Carrera 9`, cross street `5` and plate `45`. The cross street and the
  /// plate are optional.
  static ({String road, String? cross, String? plate})? parse(String address) {
    final text = address
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(_numberMark, (_) => '# ');
    final parts = text.split('#');
    if (parts.length > 2) return null;
    if (parts.length == 1) return _parseWithoutMark(text);

    final road = _normalizeRoad(parts.first);
    if (road == null) return null;

    // "5 - 45", "5-45" and "5": the plate follows the last hyphen.
    final rest = parts[1].trim();
    final hyphen = rest.lastIndexOf('-');
    if (hyphen == -1) return (road: road, cross: _normalizeNumber(rest) ?? (rest.isEmpty ? null : rest), plate: null);

    final crossText = rest.substring(0, hyphen).trim();
    final plateText = rest.substring(hyphen + 1).trim();
    final plate = RegExp(r'^\d+[A-Za-z]?$').hasMatch(plateText) ? plateText.toUpperCase() : null;
    return (
      road: road,
      cross: _normalizeNumber(crossText) ?? (crossText.isEmpty ? null : crossText),
      plate: plate,
    );
  }

  /// An address written without `#`: `Cra 9` alone, or `Cra 9 45-20` (cross
  /// street and plate after the road, common in everyday writing).
  static ({String road, String? cross, String? plate})? _parseWithoutMark(String text) {
    final road = _normalizeRoad(text);
    if (road != null) return (road: road, cross: null, plate: null);

    final match = _crossAndPlateAtTheEnd.firstMatch(text);
    if (match == null) return null;
    final roadOnly = _normalizeRoad(match.group(1)!);
    if (roadOnly == null) return null;
    return (
      road: roadOnly,
      cross: _normalizeNumber(match.group(2)!) ?? match.group(2)!.toUpperCase(),
      plate: match.group(3)!.toUpperCase(),
    );
  }

  /// "Cra 9 45-20": the road, then the cross street and the plate with a hyphen.
  static final RegExp _crossAndPlateAtTheEnd = RegExp(r'^(.+?)\s+(\d+[A-Za-z]?)\s*-\s*(\d+[A-Za-z]?)$');

  /// Words that start a road: `Carrera`, `Cra`, `Av`, `Kr`...
  static final RegExp _roadWord = RegExp(
    r'(^|[\s,])(' + _roadTypes.keys.join('|') + r')\.?(?=[\s,]|$)',
    caseSensitive: false,
  );

  /// True when the text looks like a road address (a road word and a number)
  /// whether or not [parse] understands it: the wizard tells the citizen how to
  /// write it instead of saying only "not found".
  static bool looksLikeAddress(String text) => _roadWord.hasMatch(text) && RegExp(r'\d').hasMatch(text);

  /// The searches to try, from the most to the least precise (HU-28), for an
  /// address in [city]: the plate when there is one (the building, if mapped),
  /// then the road in the neighborhood (the right stretch of a street that
  /// repeats across the city), and for free text the text itself.
  static List<String> queries({required String address, required String neighborhood, required String city}) {
    final barrio = neighborhood.trim();
    final place = [if (barrio.isNotEmpty) barrio, city.trim(), 'Colombia'].join(', ');
    final parsed = parse(address);

    if (parsed != null) {
      final cross = parsed.cross;
      final plate = parsed.plate;
      return [
        if (cross != null && plate != null) '${parsed.road} # $cross-$plate, $place',
        '${parsed.road}, $place',
      ];
    }

    final text = address.trim().replaceAll(RegExp(r'\s+'), ' ');
    return [
      '$text, $place',
      if (barrio.isNotEmpty) '$text, ${city.trim()}, Colombia',
    ];
  }

  /// "cra. 9" → "Carrera 9", "Av 6N" → "Avenida 6 Norte"; null if it does not
  /// start with a known road type followed by a number.
  static String? _normalizeRoad(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    if (words.length < 2) return null;

    final type = _roadTypes[words.first.toLowerCase().replaceAll('.', '')];
    if (type == null) return null;

    var rest = words.sublist(1);
    // "Avenida Calle 5" and "Avenida Carrera 68": the second word is part of the type.
    var fullType = type;
    final second = rest.first.toLowerCase().replaceAll('.', '');
    if (type == 'Avenida' && (second == 'calle' || second == 'carrera') && rest.length > 1) {
      fullType = 'Avenida ${_roadTypes[second]}';
      rest = rest.sublist(1);
    }

    final number = _normalizeNumber(rest.join(' '));
    return number == null ? null : '$fullType $number';
  }

  /// "10a" → "10A", "6n" → "6 Norte", "12 bis" → "12 Bis"; null if it is not a
  /// number with its suffixes.
  static String? _normalizeNumber(String text) {
    final match = _numberPattern.firstMatch(text.trim());
    if (match == null) return null;

    final letter = match.group(2)?.toUpperCase() ?? '';
    final bis = match.group(3) == null ? '' : ' Bis';
    final direction = match.group(4) == null ? '' : ' ${_directions[match.group(4)!.toLowerCase()]}';
    return '${match.group(1)}$letter$bis$direction';
  }
}

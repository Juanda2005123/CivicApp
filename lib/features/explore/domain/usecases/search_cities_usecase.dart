import '../../../auth/domain/entities/city.dart';

/// Use case: tolerant city search (HU-21). Ignores accents and case, and
/// matches the city or its department, so `bogota` finds `Bogotá`.
class SearchCitiesUseCase {
  /// Most results shown at once.
  static const int maxResults = 8;

  List<City> call(List<City> cities, String query) {
    final needle = _normalize(query.trim());
    if (needle.isEmpty) return const [];

    final startsWith = <City>[];
    final contains = <City>[];
    for (final city in cities) {
      final name = _normalize(city.name);
      if (name.startsWith(needle)) {
        startsWith.add(city);
      } else if (name.contains(needle) || _normalize(city.department).contains(needle)) {
        contains.add(city);
      }
    }
    return [...startsWith, ...contains].take(maxResults).toList();
  }

  static String _normalize(String text) {
    const from = 'áàäâéèëêíìïîóòöôúùüûñ';
    const to = 'aaaaeeeeiiiioooouuuun';
    final buffer = StringBuffer();
    for (final char in text.toLowerCase().split('')) {
      final index = from.indexOf(char);
      buffer.write(index == -1 ? char : to[index]);
    }
    return buffer.toString();
  }
}

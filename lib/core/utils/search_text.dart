/// Lower-cases [text] and strips Spanish accents, so that a search for
/// `bogota` finds `Bogotá` and `narino` finds `Nariño`. Pure Dart: the domain
/// uses it too.
String normalizeSearchText(String text) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñ';
  const to = 'aaaaeeeeiiiioooouuuun';
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    final index = from.indexOf(char);
    buffer.write(index == -1 ? char : to[index]);
  }
  return buffer.toString();
}

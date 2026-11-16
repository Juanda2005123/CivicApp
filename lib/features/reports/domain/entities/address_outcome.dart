/// How the search of a typed address ended (HU-28). The wizard shows a
/// different message for each, so the citizen knows what happened and what to
/// do next.
enum AddressOutcome {
  /// The building was found (its number is mapped).
  building,

  /// Only the street was found: the point is along the road, not at the door.
  street,

  /// Nothing matched. The map may lack that street, or the address is written
  /// in a way the service does not read. The city center stands in.
  notFound,

  /// Nothing matched, and the text looks like an address in a format that is
  /// not understood (for example `Carrera 9 con Calle 5`). The city center
  /// stands in.
  notUnderstood,

  /// The service was slow or unreachable. The city center stands in, and
  /// trying again may work.
  serviceFailed;

  /// The search located the address, so the point is an estimate of it.
  bool get isFound => this == building || this == street;
}

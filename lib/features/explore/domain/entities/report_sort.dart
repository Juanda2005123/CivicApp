/// How the Comunidad list is ordered (HU-20, criterion 3).
enum ReportSort {
  /// Newest first: how the list always arrives.
  newest,

  /// Most endorsements first; the newest breaks a tie.
  mostEndorsed,

  /// Closest to the citizen first; it needs the citizen's position.
  nearest;

  String get labelSpanish {
    switch (this) {
      case ReportSort.newest:
        return 'Más recientes';
      case ReportSort.mostEndorsed:
        return 'Más votados';
      case ReportSort.nearest:
        return 'Más cercanos';
    }
  }
}

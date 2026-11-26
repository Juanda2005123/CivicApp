/// Moment of the day the app dresses for: it picks the header photo and the
/// greeting. It is automatic, taken from the device clock; the citizen cannot
/// choose it (docs/design/04-city-identity.md, section 3).
enum DayPart {
  morning,
  afternoon,
  night;

  static const int _morningStart = 5 * 60; // 05:00
  static const int _afternoonStart = 12 * 60; // 12:00
  static const int _nightStart = 18 * 60 + 30; // 18:30

  /// Morning 05:00–11:59, afternoon 12:00–18:29, night 18:30–04:59.
  static DayPart of(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    if (minutes >= _morningStart && minutes < _afternoonStart) return morning;
    if (minutes >= _afternoonStart && minutes < _nightStart) return afternoon;
    return night;
  }

  /// How the interface names it ("Cali · tarde").
  String get labelSpanish => switch (this) {
        DayPart.morning => 'mañana',
        DayPart.afternoon => 'tarde',
        DayPart.night => 'noche',
      };
}

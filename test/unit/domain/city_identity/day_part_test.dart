import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/city_identity/domain/entities/day_part.dart';

void main() {
  DayPart at(int hour, int minute) => DayPart.of(DateTime(2026, 11, 25, hour, minute));

  group('DayPart.of', () {
    test('morning runs from 05:00 to 11:59', () {
      expect(at(5, 0), DayPart.morning);
      expect(at(8, 30), DayPart.morning);
      expect(at(11, 59), DayPart.morning);
    });

    test('afternoon runs from 12:00 to 18:29', () {
      expect(at(12, 0), DayPart.afternoon);
      expect(at(17, 0), DayPart.afternoon);
      expect(at(18, 29), DayPart.afternoon);
    });

    test('night runs from 18:30 to 04:59', () {
      expect(at(18, 30), DayPart.night);
      expect(at(23, 59), DayPart.night);
      expect(at(0, 0), DayPart.night);
      expect(at(4, 59), DayPart.night);
    });

    test('each part has its Spanish name', () {
      expect(DayPart.values.map((part) => part.labelSpanish), ['mañana', 'tarde', 'noche']);
    });
  });
}

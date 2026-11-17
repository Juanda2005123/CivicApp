import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

void main() {
  group('Coordinates.distanceInMetersTo', () {
    const cali = Coordinates(latitude: 3.4516, longitude: -76.5320);

    test('the same point is at zero meters', () {
      expect(cali.distanceInMetersTo(cali), 0);
    });

    test('0.009 degrees of latitude is about one kilometer', () {
      const north = Coordinates(latitude: 3.4606, longitude: -76.5320);

      expect(cali.distanceInMetersTo(north), closeTo(1000, 5));
    });

    test('it is symmetric', () {
      const bogota = Coordinates(latitude: 4.7110, longitude: -74.0721);

      expect(cali.distanceInMetersTo(bogota), closeTo(bogota.distanceInMetersTo(cali), 0.001));
    });

    test('Cali to Bogotá is about 300 km', () {
      const bogota = Coordinates(latitude: 4.7110, longitude: -74.0721);

      expect(cali.distanceInMetersTo(bogota) / 1000, closeTo(300, 15));
    });
  });
}

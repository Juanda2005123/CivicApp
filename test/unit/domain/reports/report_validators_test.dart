import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
import 'package:vigia_app/features/reports/domain/validators/report_validators.dart';

void main() {
  group('ReportValidators Tests', () {
    test('validateTitle accepts valid titles and rejects empty or out-of-range ones', () {
      expect(() => ReportValidators.validateTitle('Hueco profundo en vía'), returnsNormally);
      expect(
        () => ReportValidators.validateTitle('   '),
        throwsA(predicate((e) => e.toString().contains('obligatorio'))),
      );
      expect(
        () => ReportValidators.validateTitle('abc'),
        throwsA(predicate((e) => e.toString().contains('al menos 5'))),
      );
      expect(
        () => ReportValidators.validateTitle('A' * 181),
        throwsA(predicate((e) => e.toString().contains('no puede superar los 180'))),
      );
    });

    test('validateDescription accepts valid descriptions and rejects short or empty ones', () {
      expect(
        () => ReportValidators.validateDescription('Deterioro grave en la calzada derecha frente al colegio.'),
        returnsNormally,
      );
      expect(
        () => ReportValidators.validateDescription(''),
        throwsA(predicate((e) => e.toString().contains('obligatoria'))),
      );
      expect(
        () => ReportValidators.validateDescription('bache'),
        throwsA(predicate((e) => e.toString().contains('al menos 10'))),
      );
    });

    test('validateCoordinates checks Colombian continental bounding box', () {
      // Valid coordinates: Cali and Bogota
      expect(
        () => ReportValidators.validateCoordinates(const Coordinates(latitude: 3.4516, longitude: -76.5320)),
        returnsNormally,
      );
      expect(
        () => ReportValidators.validateCoordinates(const Coordinates(latitude: 4.7110, longitude: -74.0721)),
        returnsNormally,
      );

      // Coordinates outside Colombia (e.g. Madrid, New York, or south pole)
      expect(
        () => ReportValidators.validateCoordinates(const Coordinates(latitude: 40.4168, longitude: -3.7038)),
        throwsA(predicate((e) => e.toString().contains('territorio colombiano'))),
      );
      expect(
        () => ReportValidators.validateCoordinates(const Coordinates(latitude: -10.0, longitude: -75.0)),
        throwsA(predicate((e) => e.toString().contains('territorio colombiano'))),
      );
    });

    test('validateAddress and validateNeighborhood require non-empty strings', () {
      expect(() => ReportValidators.validateAddress('Calle 5 # 62-00'), returnsNormally);
      expect(() => ReportValidators.validateAddress('  '), throwsException);

      expect(() => ReportValidators.validateNeighborhood('San Fernando'), returnsNormally);
      expect(() => ReportValidators.validateNeighborhood(''), throwsException);
    });

    test('validatePhotos enforces 0-3 photo count, 5MB limit, and format rules', () {
      final validPhoto = PickedPhoto(
        bytes: Uint8List(100),
        extension: 'jpg',
        sizeInBytes: 1024,
      );

      // 0 to 3 photos allowed
      expect(() => ReportValidators.validatePhotos([]), returnsNormally);
      expect(() => ReportValidators.validatePhotos([validPhoto, validPhoto, validPhoto]), returnsNormally);

      // > 3 photos rejected
      expect(
        () => ReportValidators.validatePhotos([validPhoto, validPhoto, validPhoto, validPhoto]),
        throwsA(predicate((e) => e.toString().contains('más de 3'))),
      );

      // Over 5MB rejected
      final heavyPhoto = PickedPhoto(
        bytes: Uint8List(10),
        extension: 'png',
        sizeInBytes: 6 * 1024 * 1024,
      );
      expect(
        () => ReportValidators.validatePhotos([heavyPhoto]),
        throwsA(predicate((e) => e.toString().contains('5 MB'))),
      );

      // Unsupported extension rejected
      final invalidFormatPhoto = PickedPhoto(
        bytes: Uint8List(10),
        extension: 'gif',
        sizeInBytes: 1024,
      );
      expect(
        () => ReportValidators.validatePhotos([invalidFormatPhoto]),
        throwsA(predicate((e) => e.toString().contains('JPG, PNG o WebP'))),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/domain/validators/address_normalizer.dart';

void main() {
  group('AddressNormalizer.parse', () {
    test('reads the road, the cross street and the plate of the form output', () {
      final parsed = AddressNormalizer.parse('Carrera 9 # 5 - 45')!;

      expect(parsed.road, 'Carrera 9');
      expect(parsed.cross, '5');
      expect(parsed.plate, '45');
    });

    test('the plate and the cross street are optional', () {
      expect(AddressNormalizer.parse('Calle 5 # 9')!.plate, isNull);
      expect(AddressNormalizer.parse('Calle 5 # 9')!.cross, '9');
      expect(AddressNormalizer.parse('Calle 5')!.cross, isNull);
      expect(AddressNormalizer.parse('Calle 5')!.road, 'Calle 5');
    });

    test('expands the abbreviations people write, with or without a dot', () {
      for (final (typed, road) in [
        ('Cra 9', 'Carrera 9'),
        ('cra. 9', 'Carrera 9'),
        ('Kr 9', 'Carrera 9'),
        ('KRA 9', 'Carrera 9'),
        ('Cl 5', 'Calle 5'),
        ('cll 5', 'Calle 5'),
        ('Av 6', 'Avenida 6'),
        ('Diag 20', 'Diagonal 20'),
        ('Dg. 20', 'Diagonal 20'),
        ('Trans 4', 'Transversal 4'),
        ('Tv 4', 'Transversal 4'),
        ('Cir 3', 'Circular 3'),
        ('Autop 8', 'Autopista 8'),
      ]) {
        expect(AddressNormalizer.parse(typed)!.road, road, reason: typed);
      }
    });

    test('keeps the two-word types: Avenida Calle and Avenida Carrera', () {
      expect(AddressNormalizer.parse('Avenida Calle 5 # 38-48')!.road, 'Avenida Calle 5');
      expect(AddressNormalizer.parse('AK 68 # 12-30')!.road, 'Avenida Carrera 68');
      expect(AddressNormalizer.parse('AC 26 # 10-5')!.road, 'Avenida Calle 26');
    });

    test('writes the directions out in full, which is how OpenStreetMap names them', () {
      for (final (typed, road) in [
        ('Avenida 6N', 'Avenida 6 Norte'),
        ('Avenida 6 N', 'Avenida 6 Norte'),
        ('Av 6n', 'Avenida 6 Norte'),
        ('Calle 10 Sur', 'Calle 10 Sur'),
        ('Calle 10 s', 'Calle 10 Sur'),
        ('Carrera 3 E', 'Carrera 3 Este'),
        ('Carrera 3 O', 'Carrera 3 Oeste'),
      ]) {
        expect(AddressNormalizer.parse(typed)!.road, road, reason: typed);
      }
    });

    test('keeps the letter and the Bis of a road, and upper-cases the letter', () {
      expect(AddressNormalizer.parse('Calle 10a')!.road, 'Calle 10A');
      expect(AddressNormalizer.parse('Calle 10A Bis')!.road, 'Calle 10A Bis');
      expect(AddressNormalizer.parse('Carrera 12 bis sur')!.road, 'Carrera 12 Bis Sur');
    });

    test('N, S, E and O are directions, never the letter of the number', () {
      expect(AddressNormalizer.parse('Calle 5N')!.road, 'Calle 5 Norte');
      expect(AddressNormalizer.parse('Calle 5A')!.road, 'Calle 5A');
    });

    test('reads the number marks: No., Nº, N° and Nro. mean #', () {
      for (final typed in ['Cra 9 No. 5-45', 'Cra 9 No 5-45', 'Cra 9 Nº 5-45', 'Cra 9 N° 5-45', 'Cra 9 Nro. 5-45']) {
        final parsed = AddressNormalizer.parse(typed)!;

        expect(parsed.road, 'Carrera 9', reason: typed);
        expect(parsed.cross, '5', reason: typed);
        expect(parsed.plate, '45', reason: typed);
      }
    });

    test('tolerates extra spaces, a plate without spaces and a letter in the plate', () {
      final parsed = AddressNormalizer.parse('  Calle   5  #  9a-45B ')!;

      expect(parsed.road, 'Calle 5');
      expect(parsed.cross, '9A');
      expect(parsed.plate, '45B');
    });

    test('a reference point is not a nomenclature', () {
      expect(AddressNormalizer.parse('Frente a la estación de servicio Bellavista'), isNull);
      expect(AddressNormalizer.parse('Parque Caldas'), isNull);
    });

    test('a road type without a number, or two # marks, are not understood', () {
      expect(AddressNormalizer.parse('Carrera'), isNull);
      expect(AddressNormalizer.parse('Carrera # 5'), isNull);
      expect(AddressNormalizer.parse('Carrera 9 # 5 # 45'), isNull);
    });
  });

  group('AddressNormalizer.queries', () {
    test('a full address tries the building first, then the road in the neighborhood', () {
      final queries = AddressNormalizer.queries(
        address: 'Cra 9 # 5 - 45',
        neighborhood: 'El Modelo',
        city: 'Popayán',
      );

      expect(queries, [
        'Carrera 9 # 5-45, El Modelo, Popayán, Colombia',
        'Carrera 9, El Modelo, Popayán, Colombia',
      ]);
    });

    test('without a plate it searches the road in the neighborhood', () {
      expect(
        AddressNormalizer.queries(address: 'Calle 5 # 9', neighborhood: 'Centro', city: 'Popayán'),
        ['Calle 5, Centro, Popayán, Colombia'],
      );
    });

    test('a reference point is searched as written, with and without the neighborhood', () {
      expect(
        AddressNormalizer.queries(address: 'Frente al  parque Caldas', neighborhood: 'Centro', city: 'Popayán'),
        ['Frente al parque Caldas, Centro, Popayán, Colombia', 'Frente al parque Caldas, Popayán, Colombia'],
      );
    });

    test('without a neighborhood the city is the only place', () {
      expect(
        AddressNormalizer.queries(address: 'Carrera 9 # 5-45', neighborhood: '  ', city: 'Cali'),
        ['Carrera 9 # 5-45, Cali, Colombia', 'Carrera 9, Cali, Colombia'],
      );
      expect(
        AddressNormalizer.queries(address: 'Parque Caldas', neighborhood: '', city: 'Cali'),
        ['Parque Caldas, Cali, Colombia'],
      );
    });
  });
}

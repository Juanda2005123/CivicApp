import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/widgets/dotted_spinner.dart';
import 'package:vigia_app/features/reports/domain/entities/address_outcome.dart';
import 'package:vigia_app/features/reports/domain/entities/location_source.dart';
import 'package:vigia_app/features/reports/domain/entities/suggested_address.dart';
import 'package:vigia_app/features/reports/ui/widgets/location_pin_picker.dart';

void main() {
  Widget pickerUnderTest({
    SuggestedAddress? suggestedAddress,
    bool isSuggestingAddress = false,
    String? suggestionMessage,
    LocationSource coordinatesSource = LocationSource.cityCenter,
    bool isGeocodingAddress = false,
    AddressOutcome? addressOutcome,
    void Function(String formattedAddress)? onConfirmed,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: LocationPinPicker(
            suggestedAddress: suggestedAddress,
            isSuggestingAddress: isSuggestingAddress,
            suggestionMessage: suggestionMessage,
            coordinatesSource: coordinatesSource,
            isGeocodingAddress: isGeocodingAddress,
            addressOutcome: addressOutcome,
            onLocationConfirmed: ({
              required coordinates,
              required formattedAddress,
              required neighborhood,
              required city,
            }) =>
                onConfirmed?.call(formattedAddress),
          ),
        ),
      ),
    );
  }

  testWidgets('while the suggestion arrives, the fields it has not filled show the loading ring (HU-26)', (tester) async {
    await tester.pumpWidget(pickerUnderTest(isSuggestingAddress: true));

    expect(find.byType(DottedSpinner), findsNWidgets(2));
    expect(find.bySemanticsLabel('Buscando la vía'), findsOneWidget);
    expect(find.bySemanticsLabel('Buscando el cruce'), findsOneWidget);

    // The address arrived; only the cross street is still missing.
    await tester.pumpWidget(pickerUnderTest(
      suggestedAddress: const SuggestedAddress(roadType: 'Calle', mainRoad: '12'),
      isSuggestingAddress: true,
    ));

    expect(find.bySemanticsLabel('Buscando la vía'), findsNothing);
    expect(find.bySemanticsLabel('Buscando el cruce'), findsOneWidget);
    expect(find.text('Buscando…'), findsOneWidget);

    await tester.pumpWidget(pickerUnderTest());

    expect(find.byType(DottedSpinner), findsNothing);
    expect(find.text('Buscando…'), findsNothing);
  });

  group('main road without a number', () {
    testWidgets('a named road like Autopista Sur confirms with its name', (tester) async {
      String? confirmed;
      await tester.pumpWidget(pickerUnderTest(
        suggestedAddress: const SuggestedAddress(
          roadType: 'Autopista',
          mainRoad: 'Sur',
          crossRoad: '56',
          neighborhood: 'Pampa Linda',
        ),
        onConfirmed: (address) => confirmed = address,
      ));
      await tester.pump();

      await tester.ensureVisible(find.text('Confirmar ubicación'));
      await tester.tap(find.text('Confirmar ubicación'));
      await tester.pump();

      expect(find.text('Debe incluir número'), findsNothing);
      expect(confirmed, 'Autopista Sur # 56');
    });

    testWidgets('a numbered road type still needs a number in its main road', (tester) async {
      String? confirmed;
      await tester.pumpWidget(pickerUnderTest(
        suggestedAddress: const SuggestedAddress(
          roadType: 'Calle',
          mainRoad: 'Sur',
          crossRoad: '56',
          neighborhood: 'Pampa Linda',
        ),
        onConfirmed: (address) => confirmed = address,
      ));
      await tester.pump();

      await tester.ensureVisible(find.text('Confirmar ubicación'));
      await tester.tap(find.text('Confirmar ubicación'));
      await tester.pump();

      expect(find.text('Debe incluir número'), findsOneWidget);
      expect(confirmed, isNull);
    });
  });

  testWidgets('shows why the suggestion is incomplete', (tester) async {
    await tester.pumpWidget(pickerUnderTest(suggestionMessage: 'No encontramos el cruce. Escríbelo a mano.'));

    expect(find.text('No encontramos el cruce. Escríbelo a mano.'), findsOneWidget);
  });

  testWidgets('the late cross street does not overwrite what the citizen corrected meanwhile', (tester) async {
    await tester.pumpWidget(pickerUnderTest());
    await tester.pumpWidget(pickerUnderTest(
      suggestedAddress: const SuggestedAddress(roadType: 'Calle', mainRoad: '12', neighborhood: 'San Pedro'),
      isSuggestingAddress: true,
    ));
    await tester.enterText(find.byType(TextField).at(0), '12A');

    await tester.pumpWidget(pickerUnderTest(
      suggestedAddress: const SuggestedAddress(roadType: 'Calle', mainRoad: '12', crossRoad: '5', neighborhood: 'San Pedro'),
    ));

    expect(find.text('12A'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('San Pedro'), findsOneWidget);
  });

  group('typed address (HU-28)', () {
    Future<void> fillForm(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).at(0), '9');
      await tester.enterText(find.byType(TextField).at(1), '5');
      await tester.enterText(find.byType(TextField).at(3), 'El Modelo');
      await tester.pump();
    }

    testWidgets('says where the point comes from, in words and with an icon', (tester) async {
      for (final (source, text, icon) in [
        (LocationSource.gps, 'Tu ubicación (GPS)', Icons.gps_fixed),
        (LocationSource.mapPoint, 'Punto marcado en el mapa', Icons.push_pin_outlined),
        (LocationSource.address, 'Aproximada: según la dirección', Icons.edit_location_alt_outlined),
        (LocationSource.cityCenter, 'Aproximada: centro de la ciudad', Icons.location_city_outlined),
      ]) {
        await tester.pumpWidget(pickerUnderTest(coordinatesSource: source));

        expect(find.text(text), findsOneWidget, reason: '$source');
        expect(find.byIcon(icon), findsOneWidget, reason: '$source');
      }
    });

    testWidgets('teaches the format in both modes', (tester) async {
      await tester.pumpWidget(pickerUnderTest());

      expect(find.text('Ejemplo: Carrera 9 # 5-45 (vía, cruce y número de la puerta).'), findsOneWidget);

      await tester.tap(find.text('Punto de referencia'));
      await tester.pump();

      expect(find.textContaining('mejor escribe una dirección como Carrera 9 # 5-45'), findsOneWidget);
      expect(find.textContaining('marca el punto en el mapa'), findsOneWidget);
    });

    testWidgets('a building says it was found and has nothing else to do', (tester) async {
      await tester.pumpWidget(pickerUnderTest(addressOutcome: AddressOutcome.building));

      expect(find.textContaining('Encontramos esa dirección'), findsOneWidget);
      expect(find.text('Ajustar en el mapa'), findsNothing);
      expect(find.text('Marcar en el mapa'), findsNothing);
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('only the street found offers to adjust the point on the map', (tester) async {
      await tester.pumpWidget(pickerUnderTest(addressOutcome: AddressOutcome.street));

      expect(find.textContaining('Ubicamos la calle, pero no la puerta'), findsOneWidget);
      expect(find.text('Ajustar en el mapa'), findsOneWidget);
    });

    testWidgets('not found names the city and offers the map', (tester) async {
      await tester.pumpWidget(pickerUnderTest(addressOutcome: AddressOutcome.notFound));

      expect(find.textContaining('No encontramos esa dirección, así que dejamos el punto en el centro de Cali'), findsOneWidget);
      expect(find.textContaining('(ej. Carrera 9 # 5-45)'), findsOneWidget);
      expect(find.text('Marcar en el mapa'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('a format that is not understood says how to write it', (tester) async {
      await tester.pumpWidget(pickerUnderTest(addressOutcome: AddressOutcome.notUnderstood));

      expect(find.textContaining('Parece una dirección, pero no entendemos cómo está escrita'), findsOneWidget);
      expect(find.textContaining('Prueba con Carrera 9 # 5-45'), findsOneWidget);
      expect(find.text('Marcar en el mapa'), findsOneWidget);
    });

    testWidgets('a failed service offers to try again and the map', (tester) async {
      await tester.pumpWidget(pickerUnderTest(addressOutcome: AddressOutcome.serviceFailed));

      expect(find.textContaining('No pudimos buscar la dirección por la conexión'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Marcar en el mapa'), findsOneWidget);
    });

    testWidgets('"Reintentar" confirms the form again', (tester) async {
      final confirmed = <String>[];
      await tester.pumpWidget(pickerUnderTest(onConfirmed: confirmed.add));
      await fillForm(tester);
      await tester.pumpWidget(pickerUnderTest(addressOutcome: AddressOutcome.serviceFailed, onConfirmed: confirmed.add));

      await tester.ensureVisible(find.text('Reintentar'));
      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      expect(confirmed, ['Carrera 9 # 5']);
    });

    testWidgets('"Marcar en el mapa" opens the map picker of Step 1', (tester) async {
      await tester.pumpWidget(pickerUnderTest(addressOutcome: AddressOutcome.notFound));

      await tester.ensureVisible(find.text('Marcar en el mapa'));
      await tester.tap(find.text('Marcar en el mapa'));
      await tester.pumpAndSettle();

      expect(find.text('Selecciona el punto en el mapa'), findsOneWidget);
    });

    testWidgets('the notice goes away once the address is edited: it would be about another address', (tester) async {
      await tester.pumpWidget(pickerUnderTest());
      await fillForm(tester);
      await tester.pumpWidget(pickerUnderTest(addressOutcome: AddressOutcome.notFound));

      expect(find.textContaining('No encontramos esa dirección'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), '10');
      await tester.pump();

      expect(find.textContaining('No encontramos esa dirección'), findsNothing);
    });

    testWidgets('while it searches the confirm button shows it and ignores taps', (tester) async {
      final confirmed = <String>[];
      await tester.pumpWidget(pickerUnderTest(onConfirmed: confirmed.add));
      await fillForm(tester);
      await tester.pumpWidget(pickerUnderTest(isGeocodingAddress: true, onConfirmed: confirmed.add));

      expect(find.text('Buscando la dirección…'), findsOneWidget);
      expect(find.text('Confirmar ubicación'), findsNothing);

      await tester.tap(find.text('Buscando la dirección…'));
      await tester.pump();

      expect(confirmed, isEmpty);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/widgets/dotted_spinner.dart';
import 'package:vigia_app/features/reports/domain/entities/suggested_address.dart';
import 'package:vigia_app/features/reports/ui/widgets/location_pin_picker.dart';

void main() {
  Widget pickerUnderTest({
    SuggestedAddress? suggestedAddress,
    bool isSuggestingAddress = false,
    String? suggestionMessage,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: LocationPinPicker(
            suggestedAddress: suggestedAddress,
            isSuggestingAddress: isSuggestingAddress,
            suggestionMessage: suggestionMessage,
            onLocationConfirmed: ({
              required coordinates,
              required formattedAddress,
              required neighborhood,
              required city,
            }) {},
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
}

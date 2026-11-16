import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/widgets/validation_seal.dart';

void main() {
  Widget host(ThemeData theme, {double textScale = 1}) {
    return MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const Scaffold(body: Padding(padding: EdgeInsets.all(20), child: ValidationSeal(endorsements: 10))),
      ),
    );
  }

  group('ValidationSeal', () {
    testWidgets('says it in text, shape and a spoken label, in the light theme', (tester) async {
      await tester.pumpWidget(host(AppTheme.light));

      expect(find.text('Reporte validado por la comunidad'), findsOneWidget);
      expect(find.text('10 apoyos'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(
        find.bySemanticsLabel('Reporte validado por la comunidad, 10 apoyos'),
        findsOneWidget,
      );
    });

    testWidgets('renders in the dark theme', (tester) async {
      await tester.pumpWidget(host(AppTheme.dark));

      expect(find.text('Reporte validado por la comunidad'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('grows with a 200 % text scale without overflowing', (tester) async {
      await tester.pumpWidget(host(AppTheme.light, textScale: 2));

      expect(find.text('Reporte validado por la comunidad'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

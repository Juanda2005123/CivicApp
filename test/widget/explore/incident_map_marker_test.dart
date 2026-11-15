import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/features/explore/ui/widgets/incident_map_marker.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';

Widget _host(Widget child, ThemeData theme) {
  return MaterialApp(theme: theme, home: Scaffold(body: Center(child: child)));
}

void main() {
  for (final theme in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
    for (final severity in IncidentSeverity.values) {
      testWidgets('${severity.name} marker in ${theme.key} shows the category icon', (tester) async {
        await tester.pumpWidget(_host(
          IncidentMapMarker(
            severity: severity,
            categoryIcon: 'traffic',
            semanticLabel: 'Semáforo apagado',
            onTap: () {},
          ),
          theme.value,
        ));

        expect(find.byIcon(Icons.traffic_outlined), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('has a 48 dp tap target, a semantic label and reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(
      IncidentMapMarker(
        severity: IncidentSeverity.high,
        categoryIcon: 'warning',
        semanticLabel: 'Hueco en la Calle 5, gravedad Alta',
        onTap: () => taps++,
      ),
      AppTheme.light,
    ));

    final marker = find.byType(IncidentMapMarker);
    expect(tester.getSize(marker), const Size.square(AppSizes.touchTarget));
    expect(find.bySemanticsLabel('Hueco en la Calle 5, gravedad Alta'), findsOneWidget);

    await tester.tap(marker);
    expect(taps, 1);
  });

  test('unknown category keys fall back to a generic icon', () {
    expect(categoryIconData('something-new'), Icons.report_problem_outlined);
  });
}

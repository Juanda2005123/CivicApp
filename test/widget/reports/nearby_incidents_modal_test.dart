import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/widgets/severity_chip.dart';
import 'package:vigia_app/features/reports/domain/entities/nearby_incident.dart';
import 'package:vigia_app/features/reports/ui/widgets/nearby_incidents_modal.dart';

NearbyIncident _nearby({String severity = 'HIGH', int upvotes = 0, String? photo}) => NearbyIncident(
      id: 'inc-1',
      trackingCode: '#VIG-9331',
      title: 'Hueco profundo en carril derecho',
      categoryId: 1,
      categoryName: 'Hueco o bache en calzada',
      severity: severity,
      distanceInMeters: 43,
      primaryPhotoUrl: photo,
      upvotesCount: upvotes,
    );

Widget _host(List<NearbyIncident> incidents) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: NearbyIncidentsModal(
          nearbyIncidents: incidents,
          onEndorse: (_) {},
          onContinueDraft: () {},
        ),
      ),
    );

void main() {
  group('NearbyIncidentsModal (HU-09)', () {
    testWidgets('shows the severity in Spanish, never the database value', (tester) async {
      await tester.pumpWidget(_host([_nearby(severity: 'HIGH')]));

      expect(find.text('Alta'), findsOneWidget);
      expect(find.textContaining('HIGH'), findsNothing);
      expect(find.byType(SeverityChip), findsOneWidget);
    });

    testWidgets('writes "1 apoyo" in the singular and "N apoyos" otherwise', (tester) async {
      await tester.pumpWidget(_host([_nearby(upvotes: 1)]));
      expect(find.text('1 apoyo'), findsOneWidget);

      await tester.pumpWidget(_host([_nearby(upvotes: 3)]));
      expect(find.text('3 apoyos'), findsOneWidget);
    });

    testWidgets('a report without photo shows the hazard icon', (tester) async {
      await tester.pumpWidget(_host([_nearby()]));

      expect(find.byIcon(Icons.report_problem), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a report with photo draws it', (tester) async {
      await tester.pumpWidget(_host([_nearby(photo: 'https://example.invalid/a.jpg')]));

      expect(find.byType(Image), findsOneWidget);
    });
  });
}

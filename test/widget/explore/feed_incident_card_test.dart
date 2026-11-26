import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/widgets/rank_seal.dart';
import 'package:vigia_app/core/widgets/severity_chip.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/explore/ui/widgets/feed_incident_card.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

FeedIncident _incident({
  String? primaryPhotoUrl,
  String? reporterName = 'Ana Gomez',
  String? reporterRankName = 'Vecino Activo',
  int? reporterRankId = 2,
  IncidentStatus status = IncidentStatus.reported,
  IncidentSeverity severity = IncidentSeverity.high,
  String neighborhood = 'San Fernando',
}) =>
    FeedIncident(
      id: 'inc-1',
      trackingCode: '#VIG-8492',
      title: 'Hueco grande en la Cra 15 con Calle 9',
      neighborhood: neighborhood,
      categoryName: 'Hueco o bache en calzada',
      categoryIcon: 'warning',
      severity: severity,
      status: status,
      primaryPhotoUrl: primaryPhotoUrl,
      reporterName: reporterName,
      reporterRankName: reporterRankName,
      reporterRankId: reporterRankId,
      upvotesCount: 37,
      commentsCount: 12,
      coordinates: const Coordinates(latitude: 3.45, longitude: -76.53),
      createdAt: DateTime.utc(2026, 11, 14, 12),
    );

Widget _host(
  FeedIncident incident, {
  double? distanceMeters,
  VoidCallback? onTap,
  ThemeData? theme,
  double textScale = 1,
  double width = 400,
}) {
  return MaterialApp(
    theme: theme ?? AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: width,
              child: FeedIncidentCard(incident: incident, distanceMeters: distanceMeters, onTap: onTap ?? () {}),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('FeedIncidentCard', () {
    testWidgets('shows the code, title, neighborhood, severity, author, status, counters and date', (tester) async {
      await tester.pumpWidget(_host(_incident()));

      expect(find.text('#VIG-8492'), findsOneWidget);
      expect(find.text('Hueco grande en la Cra 15 con Calle 9'), findsOneWidget);
      expect(find.text('San Fernando'), findsOneWidget);
      expect(find.byType(SeverityChip), findsOneWidget);
      expect(find.text('Alta'), findsOneWidget);
      expect(find.text('Ana Gomez · Vecino Activo'), findsOneWidget);
      expect(find.text('Reportado'), findsOneWidget);
      expect(find.text('37'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('14/11/2026'), findsOneWidget);
    });

    testWidgets('the seal shows the rank level of the author', (tester) async {
      await tester.pumpWidget(_host(_incident(reporterRankId: 3)));

      expect(tester.widget<RankSeal>(find.byType(RankSeal)).level, 3);
    });

    testWidgets('an unknown author is anonymous, with the first seal', (tester) async {
      await tester.pumpWidget(_host(_incident(reporterName: null, reporterRankName: null, reporterRankId: null)));

      expect(find.text('Ciudadano anónimo'), findsOneWidget);
      expect(tester.widget<RankSeal>(find.byType(RankSeal)).level, 1);
    });

    testWidgets('without a photo it reserves the space with the category icon (HU-19, criterion 4)', (tester) async {
      await tester.pumpWidget(_host(_incident()));

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(LucideIcons.road), findsOneWidget);
    });

    testWidgets('with a photo it draws it, and falls back to the icon if it cannot load', (tester) async {
      await tester.pumpWidget(_host(_incident(primaryPhotoUrl: 'https://example.com/photo.jpg')));

      expect(find.byType(Image), findsOneWidget);

      // The test environment answers every network request with an error.
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(LucideIcons.road), findsOneWidget);
    });

    testWidgets('the distance shows only when it is known', (tester) async {
      await tester.pumpWidget(_host(_incident(), distanceMeters: 1250));
      expect(find.text('San Fernando · a 1,3 km'), findsOneWidget);

      await tester.pumpWidget(_host(_incident()));
      expect(find.text('San Fernando'), findsOneWidget);
      expect(find.textContaining(' km'), findsNothing);
      expect(find.textContaining('San Fernando ·'), findsNothing);
    });

    testWidgets('a report without neighborhood shows only the distance', (tester) async {
      await tester.pumpWidget(_host(_incident(neighborhood: ''), distanceMeters: 80));

      expect(find.text('a 80 m'), findsOneWidget);
    });

    testWidgets('a validated or resolved report gets the check, a pending one does not', (tester) async {
      await tester.pumpWidget(_host(_incident(status: IncidentStatus.communityValidated)));
      expect(find.text('Validado por la comunidad'), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);

      await tester.pumpWidget(_host(_incident(status: IncidentStatus.underReview)));
      expect(find.text('En revisión'), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleCheck), findsNothing);
    });

    testWidgets('the whole card is one button that speaks the report', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(_incident(), distanceMeters: 350, onTap: () => taps++));

      expect(
        find.bySemanticsLabel(
          'Reporte #VIG-8492, Hueco grande en la Cra 15 con Calle 9, gravedad Alta, barrio San Fernando, '
          'estado Reportado, a 350 m, 37 apoyos, 12 comentarios',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Hueco grande en la Cra 15 con Calle 9'));

      expect(taps, 1);
    });

    testWidgets('it draws in the dark theme too', (tester) async {
      await tester.pumpWidget(_host(_incident(), theme: AppTheme.dark));

      expect(tester.takeException(), isNull);
      expect(find.byType(SeverityChip), findsOneWidget);
    });

    testWidgets('on a narrow screen with text at 200 % nothing overflows or gets cut', (tester) async {
      await tester.pumpWidget(_host(_incident(), distanceMeters: 1250, textScale: 2, width: 320));

      expect(tester.takeException(), isNull);
      expect(find.text('Hueco grande en la Cra 15 con Calle 9'), findsOneWidget);
    });
  });

  group('formatting', () {
    test('distance: meters under a kilometer, kilometers with a decimal comma from there', () {
      expect(FeedIncidentCard.formatDistance(0), '0 m');
      expect(FeedIncidentCard.formatDistance(349.6), '350 m');
      expect(FeedIncidentCard.formatDistance(999), '999 m');
      expect(FeedIncidentCard.formatDistance(1000), '1,0 km');
      expect(FeedIncidentCard.formatDistance(12340), '12,3 km');
    });

    test('date: day, month and year with two digits', () {
      expect(FeedIncidentCard.formatDate(DateTime(2026, 3, 5, 12)), '05/03/2026');
    });
  });
}

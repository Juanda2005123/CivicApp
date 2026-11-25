import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/widgets/civic_avatar.dart';
import 'package:vigia_app/core/widgets/rank_seal.dart';

void main() {
  testWidgets('CivicAvatar displays RankSeal when avatarUrl is null or empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: CivicAvatar(avatarUrl: null, rankId: 2, size: 48, semanticLabel: 'Avatar'),
        ),
      ),
    );

    expect(find.byType(RankSeal), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('CivicAvatar displays Image when avatarUrl is provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: CivicAvatar(
            avatarUrl: 'https://example.com/avatar.jpg',
            rankId: 2,
            size: 48,
            semanticLabel: 'Avatar',
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
  });
}

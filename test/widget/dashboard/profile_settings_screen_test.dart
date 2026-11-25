import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/theme/app_theme.dart';
import 'package:vigia_app/core/theme/theme_cubit.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/update_privacy_usecase.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/privacy_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/privacy_event.dart';
import 'package:vigia_app/features/dashboard/ui/screens/profile_settings_screen.dart';

class _FakeProfileRepository implements ProfileRepository {
  bool shouldFail = false;
  bool? lastSaved;

  @override
  Future<void> createProfile(Profile profile) async {}

  @override
  Future<Profile> getProfile(String id) async => throw UnimplementedError();

  @override
  Future<void> updateLastCity(String id, String cityName) async {}

  @override
  Future<void> updatePrivacy({required String userId, required bool showRealName}) async {
    if (shouldFail) throw Exception('No pudimos guardar tu privacidad.');
    lastSaved = showRealName;
  }
}

void main() {
  Widget buildSubject(_FakeProfileRepository repo, {required bool initialShowRealName}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(
          create: (_) => PrivacyBloc(UpdatePrivacyUseCase(repo))
            ..add(PrivacyStarted(userId: 'u1', showRealName: initialShowRealName)),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const ProfileSettingsScreen(),
      ),
    );
  }

  testWidgets('shows Privacidad section and Mostrar mi nombre toggle with initial value', (tester) async {
    final repo = _FakeProfileRepository();
    await tester.pumpWidget(buildSubject(repo, initialShowRealName: false));
    await tester.pump();

    expect(find.text('Privacidad'), findsOneWidget);
    expect(find.text('Mostrar mi nombre'), findsOneWidget);

    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.value, isFalse);
  });

  testWidgets('toggling updates privacy and reverting happens on failure with error message', (tester) async {
    final repo = _FakeProfileRepository();
    await tester.pumpWidget(buildSubject(repo, initialShowRealName: true));
    await tester.pump();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(repo.lastSaved, isFalse);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);

    repo.shouldFail = true;
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isFalse);
    expect(find.text('No pudimos guardar tu privacidad.'), findsOneWidget);
  });
}

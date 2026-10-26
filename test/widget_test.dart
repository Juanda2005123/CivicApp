import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/di/injection_container.dart';
import 'package:vigia_app/main.dart';

import 'support/fakes.dart';

void main() {
  tearDown(() => sl.reset());

  testWidgets('VigiaApp smoke test renders login elements', (WidgetTester tester) async {
    await initDependencies(
      authRepository: FakeAuthRepository(),
      profileRepository: FakeProfileRepository(),
      cityRepository: FakeCityRepository(const []),
      locationRepository: FakeLocationRepository(),
    );

    await tester.pumpWidget(const VigiaApp());
    await tester.pumpAndSettle();

    expect(find.text('VIGÍA'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Register here'), findsOneWidget);
  });
}

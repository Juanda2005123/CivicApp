import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/main.dart';

void main() {
  testWidgets('VigiaApp smoke test renders login elements', (WidgetTester tester) async {
    await tester.pumpWidget(const VigiaApp());
    await tester.pumpAndSettle();

    // Verifies application title and login elements render correctly
    expect(find.text('VIGÍA'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Register here'), findsOneWidget);
  });
}

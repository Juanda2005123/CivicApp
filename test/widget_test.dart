import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/main.dart';

void main() {
  testWidgets('VigiaApp smoke test renders login elements', (WidgetTester tester) async {
    await tester.pumpWidget(const VigiaApp());
    await tester.pumpAndSettle();

    // Verifica que se renderice el título de la aplicación y el botón de login
    expect(find.text('VIGÍA'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Regístrate aquí'), findsOneWidget);
  });
}

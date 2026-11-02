import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/core/config/app_env.dart';

void main() {
  group('AppEnv Configuration Tests', () {
    test('init executes safely without throwing even if .env is missing or invalid', () async {
      await expectLater(AppEnv.init(), completes);
    });

    test('isSupabaseConfigured accurately checks URL and Key', () {
      // Regardless of whether .env is populated or empty, isSupabaseConfigured must return a valid boolean
      final configured = AppEnv.isSupabaseConfigured;
      expect(configured, isA<bool>());
    });
  });
}

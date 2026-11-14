import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/usecases/open_location_settings_usecase.dart';

import '../../support/fakes.dart';

void main() {
  test('opens the system settings through the repository', () async {
    final location = FakeLocationRepository();

    await OpenLocationSettingsUseCase(location)();

    expect(location.openSettingsCalls, 1);
  });

  test('throws a clear message when the platform cannot open them', () async {
    final location = FakeLocationRepository(canOpenSettings: false);

    await expectLater(
      OpenLocationSettingsUseCase(location)(),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('No pudimos abrir los ajustes.'),
        ),
      ),
    );
  });
}

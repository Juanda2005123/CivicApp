import '../repositories/location_repository.dart';

/// Use case: open the system settings so the user can unblock the location
/// permission (KI-01 / HU-29).
class OpenLocationSettingsUseCase {
  final LocationRepository _location;

  OpenLocationSettingsUseCase(this._location);

  Future<void> call() async {
    final opened = await _location.openSettings();
    if (!opened) {
      throw Exception(
        'No pudimos abrir los ajustes. Activa la ubicación desde la configuración de tu navegador o teléfono.',
      );
    }
  }
}

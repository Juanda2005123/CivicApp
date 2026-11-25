abstract class PrivacyEvent {}

/// Initializes the privacy view with the citizen's current setting.
class PrivacyStarted extends PrivacyEvent {
  final String userId;
  final bool showRealName;

  PrivacyStarted({required this.userId, required this.showRealName});
}

/// The citizen toggled "Mostrar mi nombre" (HU-01).
class PrivacyToggled extends PrivacyEvent {
  final bool showRealName;

  PrivacyToggled(this.showRealName);
}

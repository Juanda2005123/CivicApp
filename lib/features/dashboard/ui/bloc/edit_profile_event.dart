import '../../../auth/domain/entities/profile.dart';

abstract class EditProfileEvent {}

/// Loads the official DANE city catalog and seeds the form with [profile].
class EditProfileStarted extends EditProfileEvent {
  final Profile profile;

  EditProfileStarted(this.profile);
}

/// Requests GPS detection to pick the nearest DANE city (HU-04, criterion 3).
class EditProfileCityDetectRequested extends EditProfileEvent {}

/// Opens the OS location settings when permission is permanently denied.
class EditProfileLocationSettingsRequested extends EditProfileEvent {}

/// Submits updated name, city, and email (HU-04).
class EditProfileSaved extends EditProfileEvent {
  final String fullName;
  final String cityName;
  final String email;

  EditProfileSaved({
    required this.fullName,
    required this.cityName,
    required this.email,
  });
}

/// Submits a password change (HU-04, criterion 6).
class EditProfilePasswordChanged extends EditProfileEvent {
  final String currentPassword;
  final String newPassword;

  EditProfilePasswordChanged({
    required this.currentPassword,
    required this.newPassword,
  });
}

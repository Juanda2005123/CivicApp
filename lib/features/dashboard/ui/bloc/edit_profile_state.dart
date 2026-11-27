import '../../../auth/domain/entities/city.dart';
import '../../../auth/domain/entities/profile.dart';

enum EditProfileStatus { initial, loadingCities, saving, saved, failure }

enum PasswordChangeStatus { initial, saving, saved, failure }

enum EditProfileLocationStatus { idle, detecting, detected, blocked, error }

class EditProfileState {
  final EditProfileStatus status;
  final PasswordChangeStatus passwordStatus;
  final EditProfileLocationStatus locationStatus;
  final Profile? profile;
  final List<City> cities;
  final City? detectedCity;
  final bool emailVerificationPending;
  final String? errorMessage;
  final String? passwordErrorMessage;
  final String? locationErrorMessage;

  const EditProfileState({
    this.status = EditProfileStatus.initial,
    this.passwordStatus = PasswordChangeStatus.initial,
    this.locationStatus = EditProfileLocationStatus.idle,
    this.profile,
    this.cities = const [],
    this.detectedCity,
    this.emailVerificationPending = false,
    this.errorMessage,
    this.passwordErrorMessage,
    this.locationErrorMessage,
  });

  EditProfileState copyWith({
    EditProfileStatus? status,
    PasswordChangeStatus? passwordStatus,
    EditProfileLocationStatus? locationStatus,
    Profile? profile,
    List<City>? cities,
    City? detectedCity,
    bool? emailVerificationPending,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? passwordErrorMessage,
    bool clearPasswordErrorMessage = false,
    String? locationErrorMessage,
    bool clearLocationErrorMessage = false,
  }) {
    return EditProfileState(
      status: status ?? this.status,
      passwordStatus: passwordStatus ?? this.passwordStatus,
      locationStatus: locationStatus ?? this.locationStatus,
      profile: profile ?? this.profile,
      cities: cities ?? this.cities,
      detectedCity: detectedCity ?? this.detectedCity,
      emailVerificationPending: emailVerificationPending ?? this.emailVerificationPending,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      passwordErrorMessage:
          clearPasswordErrorMessage ? null : (passwordErrorMessage ?? this.passwordErrorMessage),
      locationErrorMessage:
          clearLocationErrorMessage ? null : (locationErrorMessage ?? this.locationErrorMessage),
    );
  }
}

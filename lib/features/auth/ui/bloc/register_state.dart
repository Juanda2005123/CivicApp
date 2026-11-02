import '../../domain/entities/city.dart';
import '../../domain/entities/profile.dart';

enum RegisterStatus { initial, loading, success, failure }

enum GpsStatus { idle, detecting, success, failure }

class RegisterState {
  final RegisterStatus status;
  final List<City> cities;
  final int? selectedCityId;
  final GpsStatus gpsStatus;
  final String? gpsMessage;
  final String? errorMessage;
  final Profile? profile;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.cities = const [],
    this.selectedCityId,
    this.gpsStatus = GpsStatus.idle,
    this.gpsMessage,
    this.errorMessage,
    this.profile,
  });

  City? get selectedCity {
    for (final city in cities) {
      if (city.id == selectedCityId) return city;
    }
    return null;
  }

  /// A plain `copyWith` cannot set a field back to `null`, so the messages
  /// have explicit clear flags.
  RegisterState copyWith({
    RegisterStatus? status,
    List<City>? cities,
    int? selectedCityId,
    GpsStatus? gpsStatus,
    String? gpsMessage,
    bool clearGpsMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    Profile? profile,
  }) {
    return RegisterState(
      status: status ?? this.status,
      cities: cities ?? this.cities,
      selectedCityId: selectedCityId ?? this.selectedCityId,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      gpsMessage: clearGpsMessage ? null : (gpsMessage ?? this.gpsMessage),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      profile: profile ?? this.profile,
    );
  }
}

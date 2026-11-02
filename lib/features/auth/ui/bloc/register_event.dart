abstract class RegisterEvent {}

/// The screen opened: load the coverage cities.
class RegisterStarted extends RegisterEvent {}

/// The citizen picked a city from the list.
class CitySelected extends RegisterEvent {
  final int cityId;

  CitySelected(this.cityId);
}

/// The citizen asked to detect the nearest city with the GPS.
class NearestCityRequested extends RegisterEvent {}

/// The citizen submitted the form. The city is the one held in the state.
class RegisterSubmitted extends RegisterEvent {
  final String fullName;
  final String email;
  final String password;

  RegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.password,
  });
}

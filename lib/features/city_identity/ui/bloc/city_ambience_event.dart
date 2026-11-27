/// What happened that may change the look of the app.
abstract class CityAmbienceEvent {}

/// The app opened: read the last city and the moment of the day.
class CityAmbienceStarted extends CityAmbienceEvent {}

/// The city being looked at is another one.
class ActiveCityChanged extends CityAmbienceEvent {
  final String name;
  final String department;

  /// True when the citizen moved from one city to another (HU-21), which draws
  /// the flag curtain; false the first time a city is known.
  final bool switched;

  ActiveCityChanged({required this.name, this.department = '', this.switched = false});
}

/// The citizen's own city (`reference_city`) is known: their rank climb uses its
/// places.
class ReferenceCityChanged extends CityAmbienceEvent {
  final String name;

  ReferenceCityChanged(this.name);
}

/// The app came back to the foreground: the moment of the day may be another.
class AppResumed extends CityAmbienceEvent {}

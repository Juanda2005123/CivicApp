abstract class MapEvent {}

/// The map tab opened (or the citizen asked to retry): load the city and its reports.
class MapStarted extends MapEvent {}

/// The citizen tapped "Centrar en mi ubicación".
class MyLocationRequested extends MapEvent {}

/// The citizen tapped "Abrir ajustes" after blocking the location permission.
class LocationSettingsRequested extends MapEvent {}

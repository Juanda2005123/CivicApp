import '../../../auth/domain/entities/city.dart';
import '../../../auth/domain/entities/coordinates.dart';
import '../../../reports/domain/entities/incident_marker.dart';

enum MapStatus { initial, loading, success, failure }

/// State of the "Centrar en mi ubicación" button, separate from the map load.
/// `blocked`: the user blocked the permission; the page offers the settings.
enum MyLocationStatus { idle, locating, found, failure, blocked }

/// Single state with a status: a reload keeps the previous markers on screen.
class MapState {
  final MapStatus status;
  final City? city;
  final List<IncidentMarker> markers;
  final String? errorMessage;
  final MyLocationStatus myLocationStatus;
  final Coordinates? myLocation;
  final String? myLocationMessage;

  const MapState({
    this.status = MapStatus.initial,
    this.city,
    this.markers = const [],
    this.errorMessage,
    this.myLocationStatus = MyLocationStatus.idle,
    this.myLocation,
    this.myLocationMessage,
  });

  MapState copyWith({
    MapStatus? status,
    City? city,
    List<IncidentMarker>? markers,
    String? errorMessage,
    bool clearErrorMessage = false,
    MyLocationStatus? myLocationStatus,
    Coordinates? myLocation,
    String? myLocationMessage,
    bool clearMyLocationMessage = false,
  }) {
    return MapState(
      status: status ?? this.status,
      city: city ?? this.city,
      markers: markers ?? this.markers,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      myLocationStatus: myLocationStatus ?? this.myLocationStatus,
      myLocation: myLocation ?? this.myLocation,
      myLocationMessage: clearMyLocationMessage ? null : (myLocationMessage ?? this.myLocationMessage),
    );
  }
}

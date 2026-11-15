import 'dart:math';

import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

import '../entities/geocoded_place.dart';
import '../entities/suggested_address.dart';
import '../repositories/geocoding_repository.dart';

/// Use case: suggest the Step 1 address from the GPS position (HU-26).
///
/// The business rule is the Colombian nomenclature: the street name becomes a
/// road type plus its number ("Calle 12" → Calle, 12) and the plate becomes
/// the cross street plus the number ("5-37" → 5, 37). A street that is not a
/// known road type ("Vía al Mar") only suggests the neighborhood.
///
/// The plate is rarely mapped, so the cross street then comes from a nearby
/// corner: a probe placed beside the main road is closer to a street that
/// crosses it than to the main road itself whenever a corner is near. Four
/// probes, two on each side, cover about 60 m ahead of and behind the
/// citizen. That street must run the other way (on a Calle, a Carrera). It is
/// a nearby corner, which is usually but not always the official cross
/// street, so the citizen reviews it.
///
/// That lookup takes several seconds, so the answer is a stream: first the
/// address as the service gave it, then, if a cross street was found, the
/// same address with it.
class SuggestAddressUseCase {
  final GeocodingRepository _geocoding;

  SuggestAddressUseCase(this._geocoding);

  /// How far each probe is from the main road, and how far ahead of or
  /// behind the citizen along it. Short enough to stay clear of the parallel
  /// street of a regular block.
  static const double probeOffsetMeters = 30;

  Stream<SuggestedAddress> call(Coordinates coordinates) async* {
    final place = await _geocoding.reverseGeocode(coordinates);
    final suggestion = parse(place);
    yield suggestion;
    final roadType = suggestion.roadType;
    final mainRoad = suggestion.mainRoad;
    if (roadType == null || mainRoad == null || suggestion.crossRoad != null) return;

    // The cross street is a bonus: if its lookup fails, keep the rest.
    try {
      final path = place.roadPath.length >= 2
          ? place.roadPath
          : (await _geocoding.streetAt(coordinates)).roadPath;
      for (final probe in probePoints(coordinates, path)) {
        final street = await _geocoding.streetAt(probe);
        final crossRoad = crossRoadFrom(roadType, mainRoad, street.road);
        if (crossRoad != null) {
          yield SuggestedAddress(
            roadType: roadType,
            mainRoad: mainRoad,
            crossRoad: crossRoad,
            neighborhood: suggestion.neighborhood,
          );
          return;
        }
      }
    } on Exception {
      return;
    }
  }

  /// Road types of the form and the spellings that map to them.
  static const Map<String, String> _roadTypes = {
    'carrera': 'Carrera',
    'cra': 'Carrera',
    'kr': 'Carrera',
    'cr': 'Carrera',
    'calle': 'Calle',
    'cl': 'Calle',
    'cll': 'Calle',
    'avenida': 'Avenida',
    'av': 'Avenida',
    'diagonal': 'Diagonal',
    'dg': 'Diagonal',
    'transversal': 'Transversal',
    'tv': 'Transversal',
    'circular': 'Circular',
    'autopista': 'Autopista',
  };

  /// Calles and diagonales run one way, carreras and transversales the other.
  /// Avenidas, circulares and autopistas can run either way.
  static const _calleLike = {'Calle', 'Diagonal'};
  static const _carreraLike = {'Carrera', 'Transversal'};

  /// "Calle 10A Bis" → (Calle, 10A Bis); null when it is not nomenclature.
  static (String, String)? _splitRoad(String? name) {
    final road = name?.trim();
    if (road == null || road.isEmpty) return null;
    final words = road.split(RegExp(r'\s+'));
    final type = _roadTypes[words.first.toLowerCase().replaceAll('.', '')];
    if (type == null || words.length < 2) return null;
    return (type, words.skip(1).join(' '));
  }

  /// Pure parsing step, public so it can be tested without a repository.
  static SuggestedAddress parse(GeocodedPlace place) {
    final road = _splitRoad(place.road);

    String? crossRoad;
    String? plot;
    final plate = place.houseNumber?.trim();
    if (road != null && plate != null) {
      // Plates come with a hyphen or with a typographic dash ("5 – 27").
      final parts = plate.split(RegExp('[-–—]'));
      if (parts.length == 2 && parts[0].trim().isNotEmpty && parts[1].trim().isNotEmpty) {
        crossRoad = parts[0].trim();
        plot = parts[1].trim();
      }
    }

    final neighborhood = place.neighborhood?.trim();
    return SuggestedAddress(
      roadType: road?.$1,
      mainRoad: road?.$2,
      crossRoad: crossRoad,
      plot: plot,
      neighborhood: (neighborhood == null || neighborhood.isEmpty) ? null : neighborhood,
    );
  }

  /// The number of [streetName] when it crosses the main road: a street of
  /// the other direction (any Calle or Carrera for an Avenida), never the
  /// main road itself. Null otherwise.
  static String? crossRoadFrom(String roadType, String mainRoad, String? streetName) {
    final road = _splitRoad(streetName);
    if (road == null) return null;
    final (type, number) = road;
    if (type == roadType && number.toLowerCase() == mainRoad.toLowerCase()) return null;
    if (_calleLike.contains(roadType)) return _carreraLike.contains(type) ? number : null;
    if (_carreraLike.contains(roadType)) return _calleLike.contains(type) ? number : null;
    return (_calleLike.contains(type) || _carreraLike.contains(type)) ? number : null;
  }

  /// Four points beside the main road, two on each side: [probeOffsetMeters]
  /// away from it, ahead of and behind the place on [path] closest to
  /// [point]. Empty when the path has no direction to measure.
  static List<Coordinates> probePoints(Coordinates point, List<Coordinates> path) {
    // A flat projection around the point is precise enough for a few meters.
    const metersPerDegree = 111320.0;
    final cosLat = cos(point.latitude * pi / 180);
    (double, double) project(Coordinates c) => (
          (c.longitude - point.longitude) * metersPerDegree * cosLat,
          (c.latitude - point.latitude) * metersPerDegree,
        );

    // Closest place on the path (the point is the origin) and the road's
    // direction there, as a unit vector.
    (double, double)? foot;
    (double, double)? direction;
    var footDistance = double.infinity;
    for (var i = 0; i + 1 < path.length; i++) {
      final (ax, ay) = project(path[i]);
      final (bx, by) = project(path[i + 1]);
      final dx = bx - ax;
      final dy = by - ay;
      final length = sqrt(dx * dx + dy * dy);
      if (length == 0) continue;
      final t = (-(ax * dx + ay * dy) / (length * length)).clamp(0.0, 1.0);
      final x = ax + t * dx;
      final y = ay + t * dy;
      final distance = sqrt(x * x + y * y);
      if (distance < footDistance) {
        footDistance = distance;
        foot = (x, y);
        direction = (dx / length, dy / length);
      }
    }
    if (foot == null || direction == null) return const [];
    final (fx, fy) = foot;
    final (ux, uy) = direction;

    Coordinates at(double along, double side) {
      final x = fx + along * probeOffsetMeters * ux - side * probeOffsetMeters * uy;
      final y = fy + along * probeOffsetMeters * uy + side * probeOffsetMeters * ux;
      return Coordinates(
        latitude: point.latitude + y / metersPerDegree,
        longitude: point.longitude + x / (metersPerDegree * cosLat),
      );
    }

    return [at(1, 1), at(-1, 1), at(1, -1), at(-1, -1)];
  }
}

import 'package:equatable/equatable.dart';

/// A bundled photo of a city and what it shows (its alternative text).
class CityPhoto extends Equatable {
  final String assetPath;
  final String description;

  const CityPhoto(this.assetPath, this.description);

  @override
  List<Object?> get props => [assetPath, description];
}

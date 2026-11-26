import 'package:equatable/equatable.dart';

/// One stripe of a city flag, top to bottom: an ARGB color and how much of the
/// height it takes compared with the others.
class FlagBand extends Equatable {
  final int color;
  final int weight;

  const FlagBand(this.color, this.weight);

  @override
  List<Object?> get props => [color, weight];
}

/// The colors of a city as ARGB integers (`0xFFF08A24`): the domain does not
/// know Flutter, `CityTheme` turns them into colors.
class CityPalette extends Equatable {
  /// Deep tone: active chips, links and labels. White text on it passes AA.
  final int deep;

  /// Warm tone: main buttons, "Reportar", the endorsement bar and confetti.
  final int accent;

  /// Text and icons on top of [accent] (4.5:1 or more).
  final int onAccent;

  /// Very dark tone laid over photos so white text can be read.
  final int veil;

  /// Flag stripes, top to bottom. Empty when the look has no flag.
  final List<FlagBand> flag;

  const CityPalette({
    required this.deep,
    required this.accent,
    required this.onAccent,
    required this.veil,
    this.flag = const [],
  });

  @override
  List<Object?> get props => [deep, accent, onAccent, veil, flag];
}

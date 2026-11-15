import 'package:equatable/equatable.dart';

/// Address suggested from the GPS for Step 1 of the wizard, split into the
/// fields of the Colombian nomenclature (HU-26). Any field may be missing; the
/// citizen reviews and completes it.
class SuggestedAddress extends Equatable {
  final String? roadType;
  final String? mainRoad;
  final String? crossRoad;
  final String? plot;
  final String? neighborhood;

  const SuggestedAddress({this.roadType, this.mainRoad, this.crossRoad, this.plot, this.neighborhood});

  @override
  List<Object?> get props => [roadType, mainRoad, crossRoad, plot, neighborhood];
}

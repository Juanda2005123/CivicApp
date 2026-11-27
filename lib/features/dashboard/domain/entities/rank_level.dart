import 'package:equatable/equatable.dart';

/// One step of the civic ladder (`civic_rank`, RN-09): the rank is earned
/// when the experience points reach [minXp].
class RankLevel extends Equatable {
  final int id;
  final String name;
  final int minXp;

  const RankLevel({required this.id, required this.name, required this.minXp});

  @override
  List<Object?> get props => [id, name, minXp];
}

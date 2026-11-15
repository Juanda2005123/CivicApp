import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/city.dart';

/// What the city switcher shows before the citizen types (HU-21): the whole
/// catalog to search in, the cities visited last and the quick shortcuts.
class CityOptions extends Equatable {
  final List<City> all;
  final List<City> recent;
  final List<City> quick;

  const CityOptions({required this.all, required this.recent, required this.quick});

  @override
  List<Object?> get props => [all, recent, quick];
}

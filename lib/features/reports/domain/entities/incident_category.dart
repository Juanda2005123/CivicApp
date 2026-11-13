import 'package:equatable/equatable.dart';

/// Taxonomy entity representing a type of road hazard or public infrastructure damage.
class IncidentCategory extends Equatable {
  final int id;
  final String name;
  final String icon;
  final String? description;

  const IncidentCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, icon, description];
}

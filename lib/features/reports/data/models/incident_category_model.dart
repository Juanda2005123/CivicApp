import '../../domain/entities/incident_category.dart';

/// DTO mapping a row of `incident_category` to the [IncidentCategory] entity.
class IncidentCategoryModel extends IncidentCategory {
  const IncidentCategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    super.description,
  });

  factory IncidentCategoryModel.fromJson(Map<String, dynamic> json) {
    return IncidentCategoryModel(
      id: json['id_category'] as int,
      name: json['name'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_category': id,
      'name': name,
      'icon': icon,
      'description': description,
    };
  }
}

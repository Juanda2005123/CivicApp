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

  /// Guaranteed natural Spanish name regardless of database seed language.
  String get displayNameSpanish {
    final lower = name.toLowerCase().trim();
    if (lower.contains('pothole') || lower.contains('hueco') || lower.contains('bache')) {
      return 'Hueco o bache en calzada';
    }
    if (lower.contains('traffic') || lower.contains('semáforo') || lower.contains('semaforo')) {
      return 'Semáforo dañado o apagado';
    }
    if (lower.contains('abandoned') || lower.contains('obra')) {
      return 'Obra pública abandonada';
    }
    if (lower.contains('sidewalk') || lower.contains('andén') || lower.contains('anden')) {
      return 'Andén o paso peatonal roto';
    }
    if (lower.contains('water') || lower.contains('fuga') || lower.contains('alcantarilla')) {
      return 'Fuga de agua o alcantarillado';
    }
    if (lower.contains('signage') || lower.contains('señal') || lower.contains('senal')) {
      return 'Señalización vial dañada';
    }
    if (lower.contains('other') || lower.contains('otro')) {
      return 'Otro daño vial';
    }
    return name;
  }

  @override
  List<Object?> get props => [id, name, icon, description];
}

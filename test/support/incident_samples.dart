import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';

/// A report of citizen `author-1` for the endorsement tests (HU-15, HU-16).
Incident sampleIncident({
  String id = 'inc-1',
  String trackingCode = '#VIG-1001',
  String reporterId = 'author-1',
  int upvotesCount = 0,
  List<String>? upvoterIds,
  IncidentStatus status = IncidentStatus.reported,
  DateTime? validatedAt,
}) {
  return Incident(
    id: id,
    trackingCode: trackingCode,
    reporterId: reporterId,
    reporterName: 'Ana Autora',
    categoryId: 1,
    title: 'Hueco profundo en carril rápido',
    description: 'Cráter de más de 20 cm de profundidad.',
    severity: IncidentSeverity.high,
    status: status,
    coordinates: const Coordinates(latitude: 3.4516, longitude: -76.5320),
    formattedAddress: 'Calle 5 con Carrera 44',
    neighborhood: 'Tequendama',
    city: 'Cali',
    upvotesCount: upvotesCount,
    upvoterIds: upvoterIds ?? List.generate(upvotesCount, (i) => 'voter-${i + 1}'),
    createdAt: DateTime(2026, 11, 12),
    validatedAt: validatedAt,
  );
}

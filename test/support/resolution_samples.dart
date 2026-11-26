import 'package:vigia_app/features/reports/domain/entities/incident_resolution.dart';

/// A repair proposal of neighbor `neighbor-1` on report `inc-1` (whose author is
/// `author-1`) for the HU-25 tests.
IncidentResolution sampleResolution({
  String id = 'res-1',
  String proponentId = 'neighbor-1',
  ResolutionStatus status = ResolutionStatus.pending,
  List<String> confirmerIds = const [],
  List<String> objectorIds = const [],
  DateTime? proposedAt,
}) {
  return IncidentResolution(
    id: id,
    incidentId: 'inc-1',
    proponentId: proponentId,
    proponentName: 'Luis Vecino',
    photoUrl: 'https://example.com/fixed.jpg',
    description: 'Ya taparon el hueco con asfalto nuevo.',
    status: status,
    confirmerIds: confirmerIds,
    objectorIds: objectorIds,
    proposedAt: proposedAt ?? DateTime(2026, 11, 20, 9),
  );
}

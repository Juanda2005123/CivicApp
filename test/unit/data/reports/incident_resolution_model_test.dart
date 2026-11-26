import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/data/models/incident_resolution_model.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_resolution.dart';

void main() {
  Map<String, dynamic> row({Object? proponent, Object? confirmations, String? resolvedAt}) => {
        'id_resolution': 'res-1',
        'id_incident': 'inc-1',
        'id_proponent_user': 'neighbor-1',
        'photo_evidence_url': 'https://x/fixed.jpg',
        'description': 'Ya taparon el hueco.',
        'status': 'PENDING',
        'confirmation_votes': 2,
        'objection_votes': 1,
        'proposed_at': '2026-11-20T09:00:00Z',
        'resolved_at': resolvedAt,
        'rejection_reason': null,
        'proponent': proponent ?? {'full_name': 'Luis Vecino', 'show_real_name': true},
        'resolution_confirmation': confirmations ??
            [
              {'id_user': 'v1'},
              {'id_user': 'v2'},
            ],
        'resolution_objection': [
          {'id_user': 'v3'},
        ],
      };

  group('IncidentResolutionModel (HU-25)', () {
    test('reads the proposal, its proponent and its votes', () {
      final model = IncidentResolutionModel.fromJson(row());

      expect(model.id, 'res-1');
      expect(model.incidentId, 'inc-1');
      expect(model.proponentId, 'neighbor-1');
      expect(model.proponentName, 'Luis Vecino');
      expect(model.photoUrl, 'https://x/fixed.jpg');
      expect(model.description, 'Ya taparon el hueco.');
      expect(model.status, ResolutionStatus.pending);
      expect(model.confirmerIds, ['v1', 'v2']);
      expect(model.objectorIds, ['v3']);
      expect(model.proposedAt, DateTime.parse('2026-11-20T09:00:00Z'));
      expect(model.resolvedAt, isNull);
    });

    test('hides the name of a proponent who keeps it private', () {
      final model = IncidentResolutionModel.fromJson(
          row(proponent: {'full_name': 'Luis Vecino', 'show_real_name': false}));

      expect(model.proponentName, isNull);
    });

    test('a fresh row without votes and a decided one', () {
      final fresh = IncidentResolutionModel.fromJson(row(confirmations: 'none')..remove('resolution_objection'));
      final decided = IncidentResolutionModel.fromJson(
          {...row(resolvedAt: '2026-11-21T10:00:00Z'), 'status': 'APPROVED_BY_COMMUNITY'});

      expect(fresh.confirmerIds, isEmpty);
      expect(fresh.objectorIds, isEmpty);
      expect(decided.status, ResolutionStatus.approvedByCommunity);
      expect(decided.resolvedAt, DateTime.parse('2026-11-21T10:00:00Z'));
    });
  });
}

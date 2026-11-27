import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/domain/usecases/toggle_endorsement_usecase.dart';

import '../../../support/fakes.dart';
import '../../../support/incident_samples.dart';

void main() {
  group('ToggleEndorsementUseCase', () {
    late FakeIncidentRepository repository;
    late ToggleEndorsementUseCase useCase;

    setUp(() {
      repository = FakeIncidentRepository();
      useCase = ToggleEndorsementUseCase(repository);
    });

    test('endorses a report the citizen has not endorsed and answers true', () async {
      final incident = sampleIncident();

      final endorsed = await useCase(incident: incident, userId: 'me');

      expect(endorsed, isTrue);
      expect(repository.calls, ['incident.endorse']);
    });

    test('revokes the endorsement the citizen already gave and answers false', () async {
      final incident = sampleIncident(upvoterIds: ['me'], upvotesCount: 1);

      final endorsed = await useCase(incident: incident, userId: 'me');

      expect(endorsed, isFalse);
      expect(repository.calls, ['incident.revoke']);
    });

    test('rejects the author endorsing their own report (RN-05) without calling the repository', () async {
      final incident = sampleIncident(reporterId: 'me');

      await expectLater(
        useCase(incident: incident, userId: 'me'),
        throwsA(predicate((e) => e.toString().contains('No puedes apoyar tu propio reporte'))),
      );
      expect(repository.calls, isEmpty);
    });

    test('rejects an empty user id with a sign-in message', () async {
      await expectLater(
        useCase(incident: sampleIncident(), userId: '  '),
        throwsA(predicate((e) => e.toString().contains('Debes iniciar sesión'))),
      );
      expect(repository.calls, isEmpty);
    });

    test('lets the repository error reach the caller', () async {
      repository.endorseError = Exception('Sin conexión');

      await expectLater(
        useCase(incident: sampleIncident(), userId: 'me'),
        throwsA(predicate((e) => e.toString().contains('Sin conexión'))),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_incident_by_id_usecase.dart';
import 'package:vigia_app/features/reports/ui/bloc/incident_detail_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/incident_detail_event.dart';
import 'package:vigia_app/features/reports/ui/bloc/incident_detail_state.dart';

import '../../../support/bloc_helpers.dart';
import '../../../support/fakes.dart';

void main() {
  group('IncidentDetailBloc Tests', () {
    late FakeIncidentRepository repository;
    late IncidentDetailBloc bloc;

    setUp(() {
      repository = FakeIncidentRepository();
      bloc = IncidentDetailBloc(
        getIncidentById: GetIncidentByIdUseCase(repository),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('IncidentDetailStarted emits loading and success when incident exists', () async {
      final incident = Incident(
        id: 'inc-1',
        trackingCode: '#VIG-1001',
        reporterId: 'user-1',
        categoryId: 1,
        title: 'Hueco en vía',
        description: 'Descripción amplia del hueco',
        severity: IncidentSeverity.medium,
        coordinates: const Coordinates(latitude: 3.45, longitude: -76.53),
        formattedAddress: 'Calle 5',
        neighborhood: 'San Fernando',
        city: 'Cali',
        createdAt: DateTime(2026, 11, 12),
      );
      repository.stored['#VIG-1001'] = incident;

      final states = await emittedStates(bloc, const IncidentDetailStarted('#VIG-1001'));

      expect(states.map((s) => s.status), [
        IncidentDetailStatus.loading,
        IncidentDetailStatus.success,
      ]);
      expect(states.last.incident?.title, 'Hueco en vía');
      expect(states.last.incident?.trackingCode, '#VIG-1001');
    });

    test('IncidentDetailStarted emits loading and failure when incident does not exist', () async {
      final states = await emittedStates(bloc, const IncidentDetailStarted('non-existent'));

      expect(states.map((s) => s.status), [
        IncidentDetailStatus.loading,
        IncidentDetailStatus.failure,
      ]);
      expect(states.last.errorMessage, isNotNull);
    });
  });
}

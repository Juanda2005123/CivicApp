import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/reports/data/datasources/resolution_remote_data_source.dart';
import 'package:vigia_app/features/reports/data/models/incident_resolution_model.dart';
import 'package:vigia_app/features/reports/data/repositories/resolution_repository_impl.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';

import '../../../support/comment_samples.dart';

class _FakeResolutionRemoteDataSource implements ResolutionRemoteDataSource {
  final List<String> calls = [];

  IncidentResolutionModel _model() => IncidentResolutionModel(
        id: 'res-1',
        incidentId: 'inc-1',
        proponentId: 'neighbor-1',
        photoUrl: 'https://x/fixed.jpg',
        description: 'Ya taparon el hueco.',
        proposedAt: DateTime(2026, 11, 20),
      );

  @override
  Future<IncidentResolutionModel?> getActiveResolution(String incidentId) async {
    calls.add('get $incidentId');
    return _model();
  }

  @override
  Future<IncidentResolutionModel> proposeResolution({
    required String incidentId,
    required String userId,
    required PickedPhoto photo,
    required String description,
  }) async {
    calls.add('propose $incidentId $userId $description');
    return _model();
  }

  @override
  Future<void> confirmResolution({required String resolutionId, required String userId}) async =>
      calls.add('confirm $resolutionId $userId');

  @override
  Future<void> objectResolution({required String resolutionId, required String userId}) async =>
      calls.add('object $resolutionId $userId');

  @override
  Future<void> acceptResolution(String resolutionId) async => calls.add('accept $resolutionId');

  @override
  Future<void> rejectResolution({required String resolutionId, required String reason}) async =>
      calls.add('reject $resolutionId $reason');
}

void main() {
  test('ResolutionRepositoryImpl delegates every action to the data source', () async {
    final remote = _FakeResolutionRemoteDataSource();
    final repository = ResolutionRepositoryImpl(remote);

    final active = await repository.getActiveResolution('inc-1');
    await repository.proposeResolution(
        incidentId: 'inc-1', userId: 'neighbor-1', photo: samplePhoto(), description: 'Ya taparon el hueco.');
    await repository.confirmResolution(resolutionId: 'res-1', userId: 'v1');
    await repository.objectResolution(resolutionId: 'res-1', userId: 'v2');
    await repository.acceptResolution('res-1');
    await repository.rejectResolution(resolutionId: 'res-1', reason: 'Solo tierra.');

    expect(active?.id, 'res-1');
    expect(remote.calls, [
      'get inc-1',
      'propose inc-1 neighbor-1 Ya taparon el hueco.',
      'confirm res-1 v1',
      'object res-1 v2',
      'accept res-1',
      'reject res-1 Solo tierra.',
    ]);
  });
}

import '../../domain/repositories/push_repository.dart';
import '../datasources/push_data_source.dart';

/// Fulfils [PushRepository] by delegating to the Firebase data source.
class PushRepositoryImpl implements PushRepository {
  final PushDataSource _remote;

  PushRepositoryImpl(this._remote);

  @override
  Future<void> enableFor(String userId) => _remote.subscribe(userId);

  @override
  Future<void> disableFor(String userId) => _remote.unsubscribe(userId);

  @override
  Stream<String> openedReports() => _remote.openedReports();
}

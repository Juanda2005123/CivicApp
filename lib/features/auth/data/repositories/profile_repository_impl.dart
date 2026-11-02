import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _dataSource;

  ProfileRepositoryImpl(this._dataSource);

  @override
  Future<void> createProfile(Profile profile) =>
      _dataSource.createProfile(ProfileModel.fromEntity(profile));

  @override
  Future<Profile> getProfile(String id) => _dataSource.getProfile(id);
}

import 'dart:typed_data';

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

  @override
  Future<void> updateLastCity(String id, String cityName) => _dataSource.updateLastCity(id, cityName);

  @override
  Future<void> updatePrivacy({required String userId, required bool showRealName}) =>
      _dataSource.updatePrivacy(id: userId, showRealName: showRealName);

  @override
  Future<void> updateProfileInfo({
    required String userId,
    required String fullName,
    required String cityName,
  }) =>
      _dataSource.updateProfileInfo(id: userId, fullName: fullName, cityName: cityName);

  @override
  Future<String> updateAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) =>
      _dataSource.updateAvatar(id: userId, bytes: bytes, extension: extension);
}

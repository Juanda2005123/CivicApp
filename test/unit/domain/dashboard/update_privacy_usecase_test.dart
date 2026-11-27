import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/update_privacy_usecase.dart';

class _FakeProfileRepository implements ProfileRepository {
  String? lastUserId;
  bool? lastShowRealName;

  @override
  Future<void> createProfile(Profile profile) async {}

  @override
  Future<Profile> getProfile(String id) async => throw UnimplementedError();

  @override
  Future<void> updateLastCity(String id, String cityName) async {}

  @override
  Future<void> updatePrivacy({required String userId, required bool showRealName}) async {
    lastUserId = userId;
    lastShowRealName = showRealName;
  }

  @override
  Future<void> updateProfileInfo({
    required String userId,
    required String fullName,
    required String cityName,
  }) async {}

  @override
  Future<String> updateAvatar({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async =>
      '';
}

void main() {
  test('UpdatePrivacyUseCase delegates userId and showRealName to ProfileRepository', () async {
    final repo = _FakeProfileRepository();
    final useCase = UpdatePrivacyUseCase(repo);

    await useCase(userId: 'user-123', showRealName: false);

    expect(repo.lastUserId, 'user-123');
    expect(repo.lastShowRealName, isFalse);
  });
}

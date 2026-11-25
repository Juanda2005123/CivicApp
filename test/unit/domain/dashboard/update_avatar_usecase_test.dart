import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/update_avatar_usecase.dart';

class _FakeProfileRepo implements ProfileRepository {
  bool shouldFail = false;
  String? uploadedUserId;
  String? uploadedExt;

  @override
  Future<void> createProfile(Profile profile) async {}

  @override
  Future<Profile> getProfile(String id) async => throw UnimplementedError();

  @override
  Future<void> updateLastCity(String id, String cityName) async {}

  @override
  Future<void> updatePrivacy({required String userId, required bool showRealName}) async {}

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
  }) async {
    if (shouldFail) throw Exception('Error al subir avatar');
    uploadedUserId = userId;
    uploadedExt = extension;
    return 'https://example.com/avatars/$userId/avatar.$extension';
  }
}

void main() {
  late _FakeProfileRepo repo;
  late UpdateAvatarUseCase useCase;

  setUp(() {
    repo = _FakeProfileRepo();
    useCase = UpdateAvatarUseCase(repo);
  });

  test('rejects unsupported image format', () async {
    expect(
      () => useCase(userId: 'u1', bytes: Uint8List(100), extension: 'gif'),
      throwsA(isA<Exception>()),
    );
  });

  test('rejects image larger than 5 MB', () async {
    final tooBig = Uint8List(5 * 1024 * 1024 + 1);
    expect(
      () => useCase(userId: 'u1', bytes: tooBig, extension: 'jpg'),
      throwsA(isA<Exception>()),
    );
  });

  test('uploads valid jpg/png/webp image under 5 MB and returns public url', () async {
    final validBytes = Uint8List(1024);
    final url = await useCase(userId: 'u1', bytes: validBytes, extension: 'png');

    expect(repo.uploadedUserId, 'u1');
    expect(repo.uploadedExt, 'png');
    expect(url, 'https://example.com/avatars/u1/avatar.png');
  });
}

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/update_privacy_usecase.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/privacy_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/privacy_event.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/privacy_state.dart';

class _FakeProfileRepository implements ProfileRepository {
  bool shouldFail = false;
  bool? savedShowRealName;

  @override
  Future<void> createProfile(Profile profile) async {}

  @override
  Future<Profile> getProfile(String id) async => throw UnimplementedError();

  @override
  Future<void> updateLastCity(String id, String cityName) async {}

  @override
  Future<void> updatePrivacy({required String userId, required bool showRealName}) async {
    if (shouldFail) throw Exception('Sin conexión. Revisa tu internet e inténtalo de nuevo.');
    savedShowRealName = showRealName;
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
  group('PrivacyBloc', () {
    late _FakeProfileRepository repo;
    late PrivacyBloc bloc;

    setUp(() {
      repo = _FakeProfileRepository();
      bloc = PrivacyBloc(UpdatePrivacyUseCase(repo));
    });

    tearDown(() => bloc.close());

    test('PrivacyStarted initializes showRealName from profile', () async {
      bloc.add(PrivacyStarted(userId: 'u1', showRealName: false));
      await expectLater(
        bloc.stream,
        emits(predicate<PrivacyState>((s) => s.userId == 'u1' && s.showRealName == false)),
      );
    });

    test('PrivacyToggled saves new value on success', () async {
      bloc.add(PrivacyStarted(userId: 'u1', showRealName: true));
      await Future<void>.delayed(Duration.zero);

      bloc.add(PrivacyToggled(false));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<PrivacyState>((s) => s.status == PrivacyStatus.saving && !s.showRealName),
          predicate<PrivacyState>((s) => s.status == PrivacyStatus.saved && !s.showRealName),
        ]),
      );
      expect(repo.savedShowRealName, isFalse);
    });

    test('PrivacyToggled reverts to previous state and emits errorMessage on failure', () async {
      repo.shouldFail = true;
      bloc.add(PrivacyStarted(userId: 'u1', showRealName: true));
      await Future<void>.delayed(Duration.zero);

      bloc.add(PrivacyToggled(false));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<PrivacyState>((s) => s.status == PrivacyStatus.saving && !s.showRealName),
          predicate<PrivacyState>(
            (s) =>
                s.status == PrivacyStatus.failure &&
                s.showRealName == true &&
                s.errorMessage == 'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
          ),
        ]),
      );
    });
  });
}

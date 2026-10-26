import 'package:flutter_test/flutter_test.dart';
import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:vigia_app/features/auth/ui/bloc/login_bloc.dart';
import 'package:vigia_app/features/auth/ui/bloc/login_event.dart';
import 'package:vigia_app/features/auth/ui/bloc/login_state.dart';
import 'package:vigia_app/features/auth/ui/bloc/startup_bloc.dart';
import 'package:vigia_app/features/auth/ui/bloc/startup_event.dart';
import 'package:vigia_app/features/auth/ui/bloc/startup_state.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_event.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_state.dart';

import '../../support/bloc_helpers.dart';
import '../../support/fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository()..stored['uid-1'] = caliProfile;
  });

  group('LoginBloc', () {
    LoginBloc buildBloc() => LoginBloc(SignInUseCase(auth, profiles));

    test('emits loading and then success with the profile', () async {
      final states = await emittedStates(
        buildBloc(),
        LoginSubmitted(email: 'ana@example.com', password: 'Abc123'),
      );

      expect(states.map((s) => s.status), [LoginStatus.loading, LoginStatus.success]);
      expect(states.last.profile, caliProfile);
    });

    test('emits the error message for invalid credentials', () async {
      auth.signInError = Exception('Invalid credentials. Please verify your email and password.');

      final states = await emittedStates(
        buildBloc(),
        LoginSubmitted(email: 'ana@example.com', password: 'bad'),
      );

      expect(states.last.status, LoginStatus.failure);
      expect(
        states.last.errorMessage,
        'Invalid credentials. Please verify your email and password.',
      );
    });
  });

  group('StartupBloc', () {
    StartupBloc buildBloc() => StartupBloc(GetCurrentProfileUseCase(auth, profiles));

    test('goes to the dashboard when a session with a profile is persisted', () async {
      auth.user = const AuthUser(id: 'uid-1', email: 'ana@example.com');

      final states = await emittedStates(buildBloc(), AppStarted());

      expect(states.single.status, StartupStatus.authenticated);
    });

    test('goes to the login when nobody is signed in', () async {
      final states = await emittedStates(buildBloc(), AppStarted());

      expect(states.single.status, StartupStatus.unauthenticated);
    });

    test('goes to the login when the session has no loadable profile', () async {
      auth.user = const AuthUser(id: 'uid-1', email: 'ana@example.com');
      profiles.getError = Exception('permission denied');

      final states = await emittedStates(buildBloc(), AppStarted());

      expect(states.single.status, StartupStatus.unauthenticated);
    });
  });

  group('ProfileBloc', () {
    ProfileBloc buildBloc() => ProfileBloc(
          GetCurrentProfileUseCase(auth, profiles),
          SignOutUseCase(auth),
        );

    test('ProfileStarted loads the profile of the active session', () async {
      auth.user = const AuthUser(id: 'uid-1', email: 'ana@example.com');

      final states = await emittedStates(buildBloc(), ProfileStarted());

      expect(states.map((s) => s.status), [ProfileStatus.loading, ProfileStatus.success]);
      expect(states.last.profile, caliProfile);
    });

    test('ProfileStarted without a session reports signedOut', () async {
      final states = await emittedStates(buildBloc(), ProfileStarted());

      expect(states.last.status, ProfileStatus.signedOut);
    });

    test('ProfileStarted reports the failure message when the profile cannot load', () async {
      auth.user = const AuthUser(id: 'uid-1', email: 'ana@example.com');
      profiles.getError = Exception('Could not load the profile: permission denied');

      final states = await emittedStates(buildBloc(), ProfileStarted());

      expect(states.last.status, ProfileStatus.failure);
      expect(states.last.errorMessage, 'Could not load the profile: permission denied');
    });

    test('SignOutRequested ends the session and reports signedOut', () async {
      auth.user = const AuthUser(id: 'uid-1', email: 'ana@example.com');

      final states = await emittedStates(buildBloc(), SignOutRequested());

      expect(states.single.status, ProfileStatus.signedOut);
      expect(auth.currentUser(), isNull);
      expect(auth.calls, ['auth.signOut']);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;
import 'package:vigia_app/core/di/injection_container.dart';
import 'package:vigia_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/city_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/location_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:vigia_app/features/auth/ui/bloc/login_bloc.dart';
import 'package:vigia_app/features/auth/ui/bloc/register_bloc.dart';
import 'package:vigia_app/features/auth/ui/bloc/startup_bloc.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/city_switcher_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/feed_bloc.dart';
import 'package:vigia_app/features/explore/ui/bloc/map_bloc.dart';
import 'package:vigia_app/features/reports/data/repositories/resolution_repository_impl.dart';
import 'package:vigia_app/features/reports/domain/repositories/resolution_repository.dart';
import 'package:vigia_app/features/reports/ui/bloc/resolution_bloc.dart';
import 'package:vigia_app/features/notifications/ui/bloc/push_bloc.dart';

void main() {
  tearDown(() => sl.reset());

  group('Dependency injection container', () {
    test('resolves every bloc through the real wiring, down to the Supabase client', () async {
      await initDependencies(
        client: SupabaseClient('https://example.supabase.co', 'anon-key'),
      );

      expect(sl<StartupBloc>(), isA<StartupBloc>());
      expect(sl<LoginBloc>(), isA<LoginBloc>());
      expect(sl<RegisterBloc>(), isA<RegisterBloc>());
      expect(sl<ProfileBloc>(), isA<ProfileBloc>());
    });

    test('resolves the blocs of the home shell: map, city switcher and community feed', () async {
      await initDependencies(
        client: SupabaseClient('https://example.supabase.co', 'anon-key'),
      );

      expect(sl<MapBloc>(), isA<MapBloc>());
      expect(sl<CitySwitcherBloc>(), isA<CitySwitcherBloc>());
      expect(sl<FeedBloc>(), isA<FeedBloc>());
      expect(identical(sl<FeedBloc>(), sl<FeedBloc>()), isFalse);
    });

    test('resolves the community resolution of a report (HU-25)', () async {
      await initDependencies(
        client: SupabaseClient('https://example.supabase.co', 'anon-key'),
      );

      expect(sl<ResolutionBloc>(), isA<ResolutionBloc>());
      expect(identical(sl<ResolutionBloc>(), sl<ResolutionBloc>()), isFalse);
      expect(sl<ResolutionRepository>(), isA<ResolutionRepositoryImpl>());
      expect(sl<PushBloc>(), isA<PushBloc>());
    });

    test('registers each implementation under its contract', () async {
      await initDependencies(
        client: SupabaseClient('https://example.supabase.co', 'anon-key'),
      );

      expect(sl<AuthRepository>(), isA<AuthRepositoryImpl>());
      expect(sl.isRegistered<ProfileRepository>(), isTrue);
      expect(sl.isRegistered<CityRepository>(), isTrue);
      expect(sl.isRegistered<LocationRepository>(), isTrue);
    });

    test('blocs are factories and use cases are singletons', () async {
      await initDependencies(
        client: SupabaseClient('https://example.supabase.co', 'anon-key'),
      );

      expect(identical(sl<LoginBloc>(), sl<LoginBloc>()), isFalse);
      expect(identical(sl<SignUpUseCase>(), sl<SignUpUseCase>()), isTrue);
    });
  });
}

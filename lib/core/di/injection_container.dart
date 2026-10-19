import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../config/app_env.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/city_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/repositories/city_repository_impl.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/city_repository.dart';
import '../../features/auth/domain/usecases/get_cities_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/ui/cubit/auth_cubit.dart';

final sl = GetIt.instance;

/// Centralized Service Locator & Dependency Injection Container (Clean Architecture).
/// Decouples UI and Domain layers from concrete Data implementations.
Future<void> initDependencies({
  AuthRepository? customAuthRepository,
  CityRepository? customCityRepository,
}) async {
  // Allow re-initialization (e.g., for test suites)
  await sl.reset();

  // 1. External & Infrastructure Layer
  SupabaseClient? client;
  if (AppEnv.isSupabaseConfigured) {
    try {
      client = Supabase.instance.client;
    } catch (_) {
      client = null;
    }
  }

  // 2. Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(
      supabaseClient: client ?? Supabase.instance.client,
    ),
  );

  sl.registerLazySingleton<CityRemoteDataSource>(
    () => CityRemoteDataSource(
      supabaseClient: client,
    ),
  );

  // 3. Repositories
  if (customAuthRepository != null) {
    sl.registerLazySingleton<AuthRepository>(() => customAuthRepository);
  } else if (AppEnv.isSupabaseConfigured && client != null) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl<AuthRemoteDataSource>()),
    );
  } else {
    sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
  }

  if (customCityRepository != null) {
    sl.registerLazySingleton<CityRepository>(() => customCityRepository);
  } else {
    sl.registerLazySingleton<CityRepository>(
      () => CityRepositoryImpl(remoteDataSource: sl<CityRemoteDataSource>()),
    );
  }

  // 4. Use Cases
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<RegisterUseCase>(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(sl<AuthRepository>()),
  );
  sl.registerLazySingleton<GetCitiesUseCase>(() => GetCitiesUseCase(sl<CityRepository>()));

  // 5. Bloc / Cubit (Factory to provide fresh instance per scope if needed)
  sl.registerFactory<AuthCubit>(
    () => AuthCubit(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
    ),
  );
}

/// Fallback mock repository for offline execution and decoupled testability
class MockAuthRepository implements AuthRepository {
  @override
  Future<User> login({required String email, required String password}) async {
    return User(
      id: 'mock-1',
      email: email,
      fullName: 'VIGÍA Citizen (Offline)',
      residenceCityId: 1,
      cityName: 'Cali (Valle del Cauca)',
      rankId: 1,
      reputationPoints: 0,
    );
  }

  @override
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required int cityId,
    String? cityName,
  }) async {
    return User(
      id: 'mock-2',
      email: email,
      fullName: fullName,
      residenceCityId: cityId,
      cityName: cityName ?? 'Cali (Valle del Cauca)',
      rankId: 1,
      reputationPoints: 0,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<User?> getCurrentUser() async => null;
}

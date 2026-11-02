import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../theme/theme_cubit.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/city_local_data_source.dart';
import '../../features/auth/data/datasources/city_remote_data_source.dart';
import '../../features/auth/data/datasources/location_data_source.dart';
import '../../features/auth/data/datasources/profile_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/repositories/city_repository_impl.dart';
import '../../features/auth/data/repositories/location_repository_impl.dart';
import '../../features/auth/data/repositories/profile_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/city_repository.dart';
import '../../features/auth/domain/repositories/location_repository.dart';
import '../../features/auth/domain/repositories/profile_repository.dart';
import '../../features/auth/domain/usecases/detect_nearest_city_usecase.dart';
import '../../features/auth/domain/usecases/get_cities_usecase.dart';
import '../../features/auth/domain/usecases/get_current_profile_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_usecase.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/auth/ui/bloc/login_bloc.dart';
import '../../features/auth/ui/bloc/register_bloc.dart';
import '../../features/auth/ui/bloc/startup_bloc.dart';
import '../../features/dashboard/ui/bloc/profile_bloc.dart';

/// Service locator. Every class receives its collaborators by constructor and
/// is registered here, once, from the inside out.
final sl = GetIt.instance;

/// Registers the whole dependency graph. Call it after `Supabase.initialize`
/// and before `runApp`.
///
/// The optional parameters let tests replace the Supabase client or a whole
/// repository; production passes nothing.
Future<void> initDependencies({
  SupabaseClient? client,
  AuthRepository? authRepository,
  ProfileRepository? profileRepository,
  CityRepository? cityRepository,
  LocationRepository? locationRepository,
}) async {
  await sl.reset();

  // Infrastructure
  sl.registerLazySingleton<SupabaseClient>(() => client ?? Supabase.instance.client);

  // Data sources
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton(() => ProfileRemoteDataSource(sl()));
  sl.registerLazySingleton(() => CityRemoteDataSource(sl()));
  sl.registerLazySingleton(() => CityLocalDataSource());
  sl.registerLazySingleton(() => LocationDataSource());

  // Repositories, registered under their contract
  sl.registerLazySingleton<AuthRepository>(
    () => authRepository ?? AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => profileRepository ?? ProfileRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CityRepository>(
    () => cityRepository ?? CityRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<LocationRepository>(
    () => locationRepository ?? LocationRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => SignUpUseCase(sl(), sl()));
  sl.registerLazySingleton(() => SignInUseCase(sl(), sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentProfileUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetCitiesUseCase(sl()));
  sl.registerLazySingleton(() => DetectNearestCityUseCase(sl(), sl()));

  // Blocs: a new instance per screen
  sl.registerFactory(() => ThemeCubit());
  sl.registerFactory(() => StartupBloc(sl()));
  sl.registerFactory(() => LoginBloc(sl()));
  sl.registerFactory(() => RegisterBloc(sl(), sl(), sl()));
  sl.registerFactory(() => ProfileBloc(sl(), sl()));
}

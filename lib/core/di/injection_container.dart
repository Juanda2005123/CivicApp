import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
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
import '../../features/auth/domain/usecases/open_location_settings_usecase.dart';
import '../../features/auth/domain/usecases/sign_in_usecase.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/auth/domain/usecases/update_privacy_usecase.dart';
import '../../features/auth/ui/bloc/login_bloc.dart';
import '../../features/auth/ui/bloc/register_bloc.dart';
import '../../features/auth/ui/bloc/startup_bloc.dart';
import '../../features/dashboard/data/datasources/impact_remote_data_source.dart';
import '../../features/dashboard/data/repositories/impact_repository_impl.dart';
import '../../features/dashboard/domain/repositories/impact_repository.dart';
import '../../features/dashboard/domain/usecases/get_civic_impact_usecase.dart';
import '../../features/dashboard/domain/usecases/get_my_reports_usecase.dart';
import '../../features/dashboard/domain/usecases/get_rank_progress_usecase.dart';
import '../../features/dashboard/ui/bloc/privacy_bloc.dart';
import '../../features/dashboard/ui/bloc/profile_bloc.dart';
import '../../features/explore/data/datasources/recent_cities_local_data_source.dart';
import '../../features/explore/data/repositories/recent_cities_repository_impl.dart';
import '../../features/explore/domain/repositories/recent_cities_repository.dart';
import '../../features/explore/domain/usecases/get_city_options_usecase.dart';
import '../../features/explore/domain/usecases/search_cities_usecase.dart';
import '../../features/explore/domain/usecases/switch_city_usecase.dart';
import '../../features/explore/ui/bloc/city_switcher_bloc.dart';
import '../../features/explore/ui/bloc/feed_bloc.dart';
import '../../features/explore/ui/bloc/map_bloc.dart';
import '../../features/reports/data/datasources/category_remote_data_source.dart';
import '../../features/reports/data/datasources/incident_remote_data_source.dart';
import '../../features/reports/data/datasources/photo_picker_data_source.dart';
import '../../features/reports/data/datasources/photo_storage_data_source.dart';
import '../../features/reports/data/repositories/category_repository_impl.dart';
import '../../features/reports/data/repositories/incident_repository_impl.dart';
import '../../features/reports/data/repositories/photo_picker_repository_impl.dart';
import '../../features/reports/domain/repositories/category_repository.dart';
import '../../features/reports/domain/repositories/incident_repository.dart';
import '../../features/reports/domain/repositories/photo_picker_repository.dart';
import '../../features/reports/domain/usecases/create_incident_usecase.dart';
import '../../features/reports/domain/usecases/endorse_incident_usecase.dart';
import '../../features/reports/domain/usecases/delete_incident_usecase.dart';
import '../../features/reports/domain/usecases/toggle_endorsement_usecase.dart';
import '../../features/reports/domain/usecases/update_incident_usecase.dart';
import '../../features/reports/domain/usecases/add_comment_usecase.dart';
import '../../features/reports/domain/usecases/delete_comment_usecase.dart';
import '../../features/reports/domain/usecases/get_comments_usecase.dart';
import '../../features/reports/domain/usecases/pick_comment_photo_usecase.dart';
import '../../features/reports/domain/repositories/comment_repository.dart';
import '../../features/reports/data/datasources/comment_remote_data_source.dart';
import '../../features/reports/data/repositories/comment_repository_impl.dart';
import '../../features/reports/ui/bloc/comments_bloc.dart';
import '../../features/reports/domain/usecases/get_categories_usecase.dart';
import '../../features/reports/domain/usecases/geocode_address_usecase.dart';
import '../../features/reports/domain/usecases/get_city_center_usecase.dart';
import '../../features/reports/domain/usecases/get_city_feed_usecase.dart';
import '../../features/reports/domain/usecases/get_city_map_usecase.dart';
import '../../features/reports/domain/usecases/get_current_location_usecase.dart';
import '../../features/reports/domain/usecases/get_incident_by_id_usecase.dart';
import '../../features/reports/domain/usecases/get_nearby_incidents_usecase.dart';
import '../../features/reports/domain/usecases/pick_photo_usecase.dart';
import '../../features/reports/data/datasources/nominatim_data_source.dart';
import '../../features/reports/data/repositories/geocoding_repository_impl.dart';
import '../../features/reports/domain/repositories/geocoding_repository.dart';
import '../../features/reports/domain/usecases/suggest_address_usecase.dart';
import '../../features/reports/ui/bloc/edit_report_bloc.dart';
import '../../features/reports/ui/bloc/incident_detail_bloc.dart';
import '../../features/reports/ui/bloc/report_wizard_bloc.dart';

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
  CategoryRepository? categoryRepository,
  IncidentRepository? incidentRepository,
  PhotoPickerRepository? photoPickerRepository,
  GeocodingRepository? geocodingRepository,
  CommentRepository? commentRepository,
  ImpactRepository? impactRepository,
}) async {
  await sl.reset();

  // Infrastructure
  sl.registerLazySingleton<SupabaseClient>(() => client ?? Supabase.instance.client);
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // Data sources
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton(() => ProfileRemoteDataSource(sl()));
  sl.registerLazySingleton(() => ImpactRemoteDataSource(sl()));
  sl.registerLazySingleton(() => CityRemoteDataSource(sl()));
  sl.registerLazySingleton(() => CityLocalDataSource());
  sl.registerLazySingleton(() => LocationDataSource());
  sl.registerLazySingleton(() => CategoryRemoteDataSource(sl()));
  sl.registerLazySingleton(() => PhotoStorageDataSource(sl()));
  sl.registerLazySingleton(() => IncidentRemoteDataSource(sl()));
  sl.registerLazySingleton(() => CommentRemoteDataSource(sl(), sl()));
  sl.registerLazySingleton(() => PhotoPickerDataSource());
  sl.registerLazySingleton(() => NominatimDataSource(sl()));
  sl.registerLazySingleton(() => RecentCitiesLocalDataSource());

  // Repositories, registered under their contract
  sl.registerLazySingleton<AuthRepository>(
    () => authRepository ?? AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => profileRepository ?? ProfileRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ImpactRepository>(
    () => impactRepository ?? ImpactRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CityRepository>(
    () => cityRepository ?? CityRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<LocationRepository>(
    () => locationRepository ?? LocationRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => categoryRepository ?? CategoryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<IncidentRepository>(
    () => incidentRepository ?? IncidentRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<CommentRepository>(
    () => commentRepository ?? CommentRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<PhotoPickerRepository>(
    () => photoPickerRepository ?? PhotoPickerRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<RecentCitiesRepository>(() => RecentCitiesRepositoryImpl(sl()));
  sl.registerLazySingleton<GeocodingRepository>(
    () => geocodingRepository ?? GeocodingRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => SignUpUseCase(sl(), sl()));
  sl.registerLazySingleton(() => SignInUseCase(sl(), sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentProfileUseCase(sl(), sl()));
  sl.registerLazySingleton(() => UpdatePrivacyUseCase(sl()));
  sl.registerLazySingleton(() => GetCivicImpactUseCase(sl()));
  sl.registerLazySingleton(() => GetRankProgressUseCase(sl()));
  sl.registerLazySingleton(() => GetMyReportsUseCase(sl()));
  sl.registerLazySingleton(() => GetCitiesUseCase(sl()));
  sl.registerLazySingleton(() => DetectNearestCityUseCase(sl(), sl()));
  sl.registerLazySingleton(() => OpenLocationSettingsUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetNearbyIncidentsUseCase(sl()));
  sl.registerLazySingleton(() => CreateIncidentUseCase(sl()));
  sl.registerLazySingleton(() => GetIncidentByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetCityMapUseCase(sl(), sl(), sl(), sl(), sl()));
  sl.registerLazySingleton(() => GetCityFeedUseCase(sl()));
  sl.registerLazySingleton(() => GetCityCenterUseCase(sl()));
  sl.registerLazySingleton(() => GeocodeAddressUseCase(sl(), sl()));
  sl.registerLazySingleton(() => EndorseIncidentUseCase(sl()));
  sl.registerLazySingleton(() => ToggleEndorsementUseCase(sl()));
  sl.registerLazySingleton(() => UpdateIncidentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteIncidentUseCase(sl()));
  sl.registerLazySingleton(() => GetCommentsUseCase(sl()));
  sl.registerLazySingleton(() => AddCommentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCommentUseCase(sl()));
  sl.registerLazySingleton(() => PickCommentPhotoUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentLocationUseCase(sl()));
  sl.registerLazySingleton(() => SuggestAddressUseCase(sl()));
  sl.registerLazySingleton(() => PickPhotoUseCase(sl()));
  sl.registerLazySingleton(() => GetCityOptionsUseCase(sl(), sl()));
  sl.registerLazySingleton(() => SearchCitiesUseCase());
  sl.registerLazySingleton(() => SwitchCityUseCase(sl(), sl(), sl()));

  // Blocs: a new instance per screen
  sl.registerFactory(() => ThemeCubit());
  sl.registerFactory(() => StartupBloc(sl()));
  sl.registerFactory(() => LoginBloc(sl()));
  sl.registerFactory(() => RegisterBloc(sl(), sl(), sl(), sl()));
  sl.registerFactory(() => ProfileBloc(sl(), sl(), sl(), sl(), sl()));
  sl.registerFactory(() => PrivacyBloc(sl()));
  sl.registerFactory(() => MapBloc(sl(), sl(), sl(), sl()));
  sl.registerFactory(() => CitySwitcherBloc(sl(), sl()));
  sl.registerFactory(() => FeedBloc(sl()));
  sl.registerFactory(
    () => ReportWizardBloc(
      sl(),
      sl(),
      sl(),
      sl(),
      sl(),
      sl(),
      sl(),
      sl(),
      sl(),
      sl(),
      sl(),
      sl(),
    ),
  );
  sl.registerFactory(() => IncidentDetailBloc(sl(), sl(), sl(), sl()));
  sl.registerFactory(() => EditReportBloc(sl(), sl(), sl(), sl()));
  sl.registerFactory(() => CommentsBloc(sl(), sl(), sl(), sl(), sl()));
}

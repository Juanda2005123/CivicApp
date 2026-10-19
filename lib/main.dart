import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'core/config/app_env.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/entities/user.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga de variables de entorno
  await AppEnv.init();

  // Inicialización de Supabase con URL y Publishable Key
  if (AppEnv.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        publishableKey: AppEnv.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Error al inicializar Supabase: $e');
    }
  }

  runApp(const VigiaApp());
}

class VigiaApp extends StatelessWidget {
  final AuthRepository? customAuthRepository;

  const VigiaApp({super.key, this.customAuthRepository});

  AuthRepository _resolveRepository() {
    if (customAuthRepository != null) return customAuthRepository!;
    if (AppEnv.isSupabaseConfigured) {
      try {
        final client = Supabase.instance.client;
        final remoteDataSource = AuthRemoteDataSource(supabaseClient: client);
        return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
      } catch (_) {
        return _MockAuthRepository();
      }
    }
    return _MockAuthRepository();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (context) {
        final repository = _resolveRepository();

        return AuthCubit(
          loginUseCase: LoginUseCase(repository),
          registerUseCase: RegisterUseCase(repository),
          logoutUseCase: LogoutUseCase(repository),
          getCurrentUserUseCase: GetCurrentUserUseCase(repository),
        )..checkAuthStatus();
      },
      child: MaterialApp(
        title: 'VIGÍA - Auditoría Vial',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.login,
        routes: AppRoutes.routes,
      ),
    );
  }
}

/// Repositorio de respaldo para pruebas locales cuando no hay red configurada
class _MockAuthRepository implements AuthRepository {
  @override
  Future<User> login({required String email, required String password}) async {
    return User(
      id: 'mock-1',
      email: email,
      fullName: 'Ciudadano VIGÍA (Offline)',
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

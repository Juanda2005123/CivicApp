import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'core/config/app_env.dart';
import 'core/constants/app_routes.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/register_usecase.dart';
import 'features/auth/ui/cubit/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables
  await AppEnv.init();

  // 2. Initialize Supabase if credentials are provided
  if (AppEnv.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        publishableKey: AppEnv.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
    }
  }

  // 3. Initialize Clean Architecture Dependency Injection container (GetIt)
  await initDependencies();

  runApp(const VigiaApp());
}

class VigiaApp extends StatelessWidget {
  final AuthRepository? customAuthRepository;

  const VigiaApp({super.key, this.customAuthRepository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (context) {
        if (customAuthRepository != null) {
          return AuthCubit(
            loginUseCase: LoginUseCase(customAuthRepository!),
            registerUseCase: RegisterUseCase(customAuthRepository!),
            logoutUseCase: LogoutUseCase(customAuthRepository!),
            getCurrentUserUseCase: GetCurrentUserUseCase(customAuthRepository!),
          )..checkAuthStatus();
        }

        if (sl.isRegistered<AuthCubit>()) {
          return sl<AuthCubit>()..checkAuthStatus();
        }

        final fallbackRepo = MockAuthRepository();
        return AuthCubit(
          loginUseCase: LoginUseCase(fallbackRepo),
          registerUseCase: RegisterUseCase(fallbackRepo),
          logoutUseCase: LogoutUseCase(fallbackRepo),
          getCurrentUserUseCase: GetCurrentUserUseCase(fallbackRepo),
        )..checkAuthStatus();
      },
      child: MaterialApp(
        title: 'VIGÍA - Civic Road Audit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.login,
        routes: AppRoutes.routes,
      ),
    );
  }
}

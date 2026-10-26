import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/ui/bloc/login_bloc.dart';
import '../../features/auth/ui/bloc/register_bloc.dart';
import '../../features/auth/ui/bloc/register_event.dart';
import '../../features/auth/ui/bloc/startup_bloc.dart';
import '../../features/auth/ui/bloc/startup_event.dart';
import '../../features/auth/ui/screens/login_screen.dart';
import '../../features/auth/ui/screens/register_screen.dart';
import '../../features/auth/ui/screens/splash_screen.dart';
import '../../features/dashboard/ui/bloc/profile_bloc.dart';
import '../../features/dashboard/ui/bloc/profile_event.dart';
import '../../features/dashboard/ui/screens/dashboard_screen.dart';
import '../di/injection_container.dart';

/// Named routes of VIGÍA. Each route wraps its screen in the `BlocProvider`
/// that creates the screen's Bloc from the service locator.
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => BlocProvider(
              create: (_) => sl<StartupBloc>()..add(AppStarted()),
              child: const SplashScreen(),
            ),
        login: (context) => BlocProvider(
              create: (_) => sl<LoginBloc>(),
              child: const LoginScreen(),
            ),
        register: (context) => BlocProvider(
              create: (_) => sl<RegisterBloc>()..add(RegisterStarted()),
              child: const RegisterScreen(),
            ),
        dashboard: (context) => BlocProvider(
              create: (_) => sl<ProfileBloc>()..add(ProfileStarted()),
              child: const DashboardScreen(),
            ),
      };
}

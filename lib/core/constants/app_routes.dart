import 'package:flutter/material.dart';
import '../di/injection_container.dart';
import '../../features/auth/domain/usecases/get_cities_usecase.dart';
import '../../features/auth/ui/screens/login_screen.dart';
import '../../features/auth/ui/screens/register_screen.dart';
import '../../features/dashboard/ui/screens/dashboard_screen.dart';

/// Centralización de rutas nombradas de VIGÍA.
/// Vincula las capas UI de cada feature.
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    register: (context) => RegisterScreen(
      getCitiesUseCase: sl.isRegistered<GetCitiesUseCase>() ? sl<GetCitiesUseCase>() : null,
    ),
    dashboard: (context) => const DashboardScreen(),
  };
}

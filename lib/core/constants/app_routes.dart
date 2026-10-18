import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/dashboard_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';

/// Centralización de rutas nombradas de VIGÍA (Lecciones 0034 y 0035).
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    dashboard: (context) => const DashboardScreen(),
  };
}

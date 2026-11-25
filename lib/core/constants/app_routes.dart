import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/domain/entities/profile.dart';
import '../../features/auth/ui/bloc/login_bloc.dart';
import '../../features/auth/ui/bloc/register_bloc.dart';
import '../../features/auth/ui/bloc/register_event.dart';
import '../../features/auth/ui/bloc/startup_bloc.dart';
import '../../features/auth/ui/bloc/startup_event.dart';
import '../../features/auth/ui/screens/login_screen.dart';
import '../../features/auth/ui/screens/register_screen.dart';
import '../../features/auth/ui/screens/splash_screen.dart';
import '../../features/dashboard/ui/bloc/privacy_bloc.dart';
import '../../features/dashboard/ui/bloc/privacy_event.dart';
import '../../features/dashboard/ui/bloc/profile_bloc.dart';
import '../../features/dashboard/ui/bloc/profile_event.dart';
import '../../features/dashboard/ui/screens/profile_settings_screen.dart';
import '../../features/explore/ui/bloc/city_switcher_bloc.dart';
import '../../features/explore/ui/bloc/feed_bloc.dart';
import '../../features/explore/ui/bloc/map_bloc.dart';
import '../../features/explore/ui/bloc/map_event.dart';
import '../../features/explore/ui/screens/home_screen.dart';
import '../../features/reports/ui/bloc/comments_bloc.dart';
import '../../features/reports/ui/bloc/edit_report_bloc.dart';
import '../../features/reports/ui/bloc/incident_detail_bloc.dart';
import '../../features/reports/ui/bloc/report_wizard_bloc.dart';
import '../../features/reports/ui/bloc/report_wizard_event.dart';
import '../../features/reports/ui/screens/edit_report_screen.dart';
import '../../features/reports/ui/screens/incident_detail_screen.dart';
import '../../features/reports/ui/screens/report_wizard_screen.dart';
import '../di/injection_container.dart';

/// Named routes of VIGÍA. Each route wraps its screen in the `BlocProvider`
/// that creates the screen's Bloc from the service locator.
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String reportWizard = '/report-wizard';
  static const String reportDetail = '/report-detail';
  static const String reportEdit = '/report-edit';
  static const String profileSettings = '/profile-settings';

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
        home: (context) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<ProfileBloc>()..add(ProfileStarted())),
                BlocProvider(create: (_) => sl<MapBloc>()..add(MapStarted())),
                BlocProvider(create: (_) => sl<CitySwitcherBloc>()),
                BlocProvider(create: (_) => sl<FeedBloc>()),
              ],
              child: const HomeScreen(),
            ),
        reportWizard: (context) => BlocProvider(
              create: (_) => sl<ReportWizardBloc>()..add(WizardStarted()),
              child: const ReportWizardScreen(),
            ),
        reportEdit: (context) => BlocProvider(
              create: (_) => sl<EditReportBloc>(),
              child: const EditReportScreen(),
            ),
        reportDetail: (context) => MultiBlocProvider(
              providers: [
                BlocProvider(create: (_) => sl<IncidentDetailBloc>()),
                BlocProvider(create: (_) => sl<CommentsBloc>()),
              ],
              child: const IncidentDetailScreen(),
            ),
        profileSettings: (context) {
          final profile = ModalRoute.of(context)!.settings.arguments as Profile;
          return BlocProvider(
            create: (_) => sl<PrivacyBloc>()
              ..add(PrivacyStarted(userId: profile.id, showRealName: profile.showRealName)),
            child: const ProfileSettingsScreen(),
          );
        },
      };
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_env.dart';
import 'core/constants/app_routes.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/city_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/widgets/configuration_error_screen.dart';
import 'features/city_identity/ui/bloc/city_ambience_bloc.dart';
import 'features/city_identity/ui/bloc/city_ambience_event.dart';
import 'features/city_identity/ui/bloc/city_ambience_state.dart';
import 'features/city_identity/ui/widgets/city_ambience_scope.dart';
import 'firebase_options.dart';

/// A push that arrives with the app closed or in the background (HU-24). Android
/// shows it by itself; this only has to exist, outside any class (lesson K3).
@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Push en segundo plano: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppEnv.init();
  if (!AppEnv.isSupabaseConfigured) {
    runApp(const ConfigurationErrorApp());
    return;
  }

  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    publishableKey: AppEnv.supabaseAnonKey,
  );
  // Push notifications (HU-24) exist only where Firebase is configured: Android.
  if (DefaultFirebaseOptions.isSupported) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
  }
  await initDependencies();

  runApp(const VigiaApp());
}

class VigiaApp extends StatelessWidget {
  const VigiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The two app-wide pieces: light or dark (the citizen's choice) and the
    // city look (the city being explored and the moment of the day).
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ThemeCubit>()),
        BlocProvider(create: (_) => sl<CityAmbienceBloc>()..add(CityAmbienceStarted())),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => BlocBuilder<CityAmbienceBloc, CityAmbienceState>(
          builder: (context, ambience) {
            ThemeData themeFor(Brightness brightness) => AppTheme.build(
                  brightness,
                  CityTheme.from(
                    ambience.identity,
                    brightness,
                    ambience.dayPart,
                    reference: ambience.reference,
                    featured: ambience.featured,
                  ),
                );

            return MaterialApp(
              title: 'VIGÍA · Veeduría vial ciudadana',
              debugShowCheckedModeBanner: false,
              theme: themeFor(Brightness.light),
              darkTheme: themeFor(Brightness.dark),
              themeMode: themeMode,
              themeAnimationStyle: _themeAnimation(context, ambience),
              builder: (context, child) => CityAmbienceScope(child: child!),
              initialRoute: AppRoutes.splash,
              routes: AppRoutes.routes,
            );
          },
        ),
      ),
    );
  }

  /// Moving to another city, the theme changes at once behind the curtain. With
  /// reduced motion every change is a 100 ms fade.
  AnimationStyle? _themeAnimation(BuildContext context, CityAmbienceState ambience) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return const AnimationStyle(duration: AppMotion.reduced);
    }
    if (!ambience.arrivedBySwitch) return null;
    return const AnimationStyle(duration: AppMotion.curtainIn, curve: Threshold(0.95));
  }
}

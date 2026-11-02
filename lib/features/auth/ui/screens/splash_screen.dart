import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../bloc/startup_bloc.dart';
import '../bloc/startup_state.dart';

/// First screen: checks the persisted session and routes the citizen. It is
/// always on ink, in light and dark: it is the brand moment.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<StartupBloc, StartupState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case StartupStatus.authenticated:
            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          case StartupStatus.unauthenticated:
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          case StartupStatus.checking:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _StampIn(
                child: BrandMark(
                  sealSize: 112,
                  wordmarkSize: 38,
                  tagline: 'Tu voz, con evidencia.',
                  onInk: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Semantics(
                label: 'Cargando',
                child: SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: const LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.mustard,
                      backgroundColor: AppColors.inkLine,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The seal "stamps" onto the screen: scale 1.18 to 1 with a fade (320 ms).
/// With reduced motion it only fades.
class _StampIn extends StatelessWidget {
  final Widget child;

  const _StampIn({required this.child});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduce ? AppMotion.reduced : AppMotion.emphasized,
      curve: AppMotion.curve,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: reduce ? 1 : 1.18 - 0.18 * t, child: child),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/civic_background.dart';
import '../../../../core/widgets/civic_brand_header.dart';
import '../bloc/startup_bloc.dart';
import '../bloc/startup_state.dart';

/// First screen: checks the persisted session and routes the citizen.
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
      child: const Scaffold(
        body: CivicBackground(
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CivicBrandHeader(),
                  SizedBox(height: 28),
                  CircularProgressIndicator(strokeWidth: 2.5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

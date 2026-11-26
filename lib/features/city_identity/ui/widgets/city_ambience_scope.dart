import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/city_theme.dart';
import '../../../../core/widgets/city/city_motion.dart';
import '../bloc/city_ambience_bloc.dart';
import '../bloc/city_ambience_event.dart';
import '../bloc/city_ambience_state.dart';

/// Around the app, inside `MaterialApp`: tells the [CityAmbienceBloc] when the
/// app comes back to the foreground, loads the new header photo ahead of time
/// and draws the flag curtain when the citizen moves to another city (7A).
class CityAmbienceScope extends StatefulWidget {
  final Widget child;

  const CityAmbienceScope({super.key, required this.child});

  @override
  State<CityAmbienceScope> createState() => _CityAmbienceScopeState();
}

class _CityAmbienceScopeState extends State<CityAmbienceScope> with SingleTickerProviderStateMixin {
  late final AppLifecycleListener _lifecycle;
  late final AnimationController _curtain;
  List<CityFlagBand> _flag = const [];

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: () => context.read<CityAmbienceBloc>().add(AppResumed()));
    _curtain = AnimationController(vsync: this, duration: FlagCurtain.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) setState(() => _flag = const []);
      });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _curtain.dispose();
    super.dispose();
  }

  CityTheme _themeOf(CityAmbienceState state) =>
      CityTheme.from(state.identity, Theme.of(context).brightness, state.dayPart);

  void _precacheHero(CityAmbienceState state) {
    final hero = _themeOf(state).hero;
    if (hero != null) precacheImage(hero, context, onError: (_, _) {});
  }

  void _drawCurtain(CityAmbienceState state) {
    final flag = _themeOf(state).flag;
    // Reduced motion: the theme itself fades in 100 ms. A look without a flag
    // has nothing to sweep.
    if (flag.isEmpty || AppMotion.reduceOf(context)) return;
    setState(() => _flag = flag);
    _curtain.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CityAmbienceBloc, CityAmbienceState>(
          listenWhen: (previous, current) =>
              previous.identity != current.identity || previous.dayPart != current.dayPart,
          listener: (context, state) => _precacheHero(state),
        ),
        BlocListener<CityAmbienceBloc, CityAmbienceState>(
          listenWhen: (previous, current) => current.citySwitches > previous.citySwitches,
          listener: (context, state) => _drawCurtain(state),
        ),
      ],
      child: Stack(
        children: [
          widget.child,
          if (_flag.isNotEmpty) Positioned.fill(child: FlagCurtain(flag: _flag, progress: _curtain)),
        ],
      ),
    );
  }
}

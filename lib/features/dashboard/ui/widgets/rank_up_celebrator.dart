import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/city_theme.dart';
import '../../../../core/widgets/city/celebration_overlay.dart';
import '../../domain/entities/rank_level.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_state.dart';
import 'rank_climb.dart';

/// 4C, a new rank (RN-09). It watches the [ProfileBloc] for a rank higher than
/// the one it last showed and, as soon as "Mi perfil" is in sight, opens the
/// photo of that place from its medal. Coming from another tab or screen, the
/// celebration waits until the citizen is back.
class RankUpCelebrator extends StatefulWidget {
  /// The key of the current rank's medal.
  final GlobalKey medalKey;
  final Widget child;

  const RankUpCelebrator({super.key, required this.medalKey, required this.child});

  @override
  State<RankUpCelebrator> createState() => _RankUpCelebratorState();
}

class _RankUpCelebratorState extends State<RankUpCelebrator> {
  /// The rank reached and not celebrated yet.
  RankLevel? _pending;
  bool _scheduled = false;

  Future<void> _celebrate() async {
    final rank = _pending;
    _scheduled = false;
    if (rank == null || !mounted) return;
    _pending = null;

    final medal = widget.medalKey.currentContext;
    if (medal != null) {
      await Scrollable.ensureVisible(
        medal,
        alignment: 0.5,
        duration: AppMotion.reduceOf(context) ? Duration.zero : AppMotion.standard,
        curve: AppMotion.curve,
      );
    }
    if (!mounted) return;

    final box = widget.medalKey.currentContext?.findRenderObject();
    await showRankCelebration(
      context,
      level: rank.id,
      rankName: rank.name,
      place: RankClimb.trailRankOf(rank).landmarkIn(CityTheme.of(context).landmarks),
      points: rank.minXp,
      origin: box is RenderBox && box.hasSize ? box.localToGlobal(box.size.center(Offset.zero)) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // A hidden tab or a covered screen has its tickers muted.
    final inSight = TickerMode.valuesOf(context).enabled;
    if (inSight && _pending != null && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
    }

    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) {
        final before = previous.rankProgress;
        final after = current.rankProgress;
        return before != null && after != null && after.current.id > before.current.id;
      },
      listener: (context, state) => setState(() => _pending = state.rankProgress!.current),
      child: widget.child,
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../features/city_identity/domain/entities/city_identity.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/city_theme.dart';
import '../brand_seal.dart';
import '../rank_seal.dart';
import 'flag_stripe.dart';

/// The two great moments (docs/design/04-city-identity.md, section 6). Both
/// cover the screen, close on a tap and close by themselves.

/// 3A: the report reached the community validation. The seal drops turning and
/// bounces, a wave leaves it and confetti in the flag's colors falls.
Future<void> showValidationCelebration(
  BuildContext context, {
  required String reportCode,
  required int endorsements,
}) {
  final reduce = AppMotion.reduceOf(context);
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: reduce ? AppMotion.reduced : AppMotion.standard,
      reverseTransitionDuration: reduce ? AppMotion.reduced : AppMotion.standard,
      pageBuilder: (_, _, _) => ValidationCelebration(reportCode: reportCode, endorsements: endorsements),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// 4C: a new rank (RN-09). The photo of its place opens in a circle from
/// [origin] (its medal) until it fills the screen.
Future<void> showRankCelebration(
  BuildContext context, {
  required int level,
  required String rankName,
  required CityLandmark? place,
  int? points,
  Offset? origin,
}) {
  final reduce = AppMotion.reduceOf(context);
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: reduce ? AppMotion.reduced : AppMotion.reveal,
      reverseTransitionDuration: reduce ? AppMotion.reduced : AppMotion.standard,
      pageBuilder: (_, _, _) => RankCelebration(level: level, rankName: rankName, place: place, points: points),
      transitionsBuilder: (context, animation, _, child) {
        if (reduce || animation.status == AnimationStatus.reverse) {
          return FadeTransition(opacity: animation, child: child);
        }
        final grow = animation.drive(CurveTween(curve: AppMotion.curve));
        return AnimatedBuilder(
          animation: grow,
          child: child,
          builder: (context, child) => ClipPath(
            clipper: CircleRevealClipper(share: grow.value, origin: origin),
            child: child,
          ),
        );
      },
    ),
  );
}

/// A circle that grows from [origin] (the center when null) until it covers the
/// whole area.
class CircleRevealClipper extends CustomClipper<Path> {
  final double share;
  final Offset? origin;

  const CircleRevealClipper({required this.share, this.origin});

  @override
  Path getClip(Size size) {
    final center = origin ?? size.center(Offset.zero);
    final farthest = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((corner) => (corner - center).distance).reduce(math.max);
    return Path()..addOval(Rect.fromCircle(center: center, radius: farthest * share));
  }

  @override
  bool shouldReclip(CircleRevealClipper oldClipper) => oldClipper.share != share || oldClipper.origin != origin;
}

/// Closes itself after [hold] (one controller, which also drives the motion) or
/// on a tap.
class _SelfClosing extends StatefulWidget {
  final Duration hold;
  final String semanticLabel;
  final Widget Function(BuildContext context, Animation<double> time) builder;

  const _SelfClosing({required this.hold, required this.semanticLabel, required this.builder});

  @override
  State<_SelfClosing> createState() => _SelfClosingState();
}

class _SelfClosingState extends State<_SelfClosing> with SingleTickerProviderStateMixin {
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: widget.hold,
    // The timing is the same with reduced motion: only the movement goes away.
    animationBehavior: AnimationBehavior.preserve,
  )
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _close();
    })
    ..forward();

  bool _closed = false;

  void _close() {
    if (_closed || !mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    _closed = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: Semantics(
        namesRoute: true,
        liveRegion: true,
        button: true,
        label: '${widget.semanticLabel}. Toca para cerrar.',
        onTap: _close,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _close,
          child: Material(color: CityTheme.of(context).veil, child: widget.builder(context, _time)),
        ),
      ),
    );
  }
}

/// The content of the validation celebration (3A).
class ValidationCelebration extends StatelessWidget {
  final String reportCode;
  final int endorsements;

  const ValidationCelebration({super.key, required this.reportCode, required this.endorsements});

  /// Bonus the author of a report gets at the community validation (RN-08).
  static const int validationBonus = 500;

  @override
  Widget build(BuildContext context) {
    final city = CityTheme.of(context);
    final reduce = AppMotion.reduceOf(context);
    final message = '$endorsements vecinos confirmaron el daño. Ya tiene el sello de la comunidad.';
    const bonus = '+$validationBonus XP para quien lo reportó';

    return _SelfClosing(
      hold: AppMotion.validationHold,
      semanticLabel: 'Reporte $reportCode validado. ${city.copy.validationCheer} $message $bonus',
      builder: (context, time) => Stack(
        children: [
          if (!reduce) Positioned.fill(child: _Confetti(time: time)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'REPORTE $reportCode',
                      style: AppTextStyles.eyebrow.copyWith(color: CityTheme.onVeil),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _Seal(time: time, animate: !reduce),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      city.copy.validationCheer,
                      textAlign: TextAlign.center,
                      // Anton is for a city's own words; the default look keeps Fraunces.
                      style: (city.level == CityIdentityLevel.fallback
                              ? AppTextStyles.headline
                              : AppTextStyles.cityHeadline)
                          .copyWith(color: CityTheme.onVeil),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth * 0.7),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(color: CityTheme.onVeil),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      bonus,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.data(size: 16, line: 24).copyWith(color: city.accent),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Toca para cerrar', style: AppTextStyles.caption.copyWith(color: CityTheme.onVeil)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dotted seal with the city's place inside (the brand mark without photos).
class _Seal extends StatelessWidget {
  final Animation<double> time;
  final bool animate;

  const _Seal({required this.time, required this.animate});

  /// Share of the whole celebration at which [moment] happens.
  static double _at(Duration moment) => moment.inMicroseconds / AppMotion.validationHold.inMicroseconds;

  @override
  Widget build(BuildContext context) {
    final city = CityTheme.of(context);
    final photo = city.landmarks.length > 1 ? city.landmarks[1].photo : null;
    const size = AppSizes.celebrationSeal;

    final seal = SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size.square(size), painter: _SealRingPainter(city.accent)),
          if (photo == null)
            const BrandSeal(size: size - AppSpacing.xl, variant: SealVariant.onDark)
          else
            ClipOval(
              child: Image(
                image: photo,
                width: size - AppSpacing.xl,
                height: size - AppSpacing.xl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const BrandSeal(size: size - AppSpacing.xl, variant: SealVariant.onDark),
              ),
            ),
          Positioned(
            bottom: -AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs / 2),
              decoration: BoxDecoration(color: city.accent, borderRadius: BorderRadius.circular(AppRadii.chip)),
              child: Text('VALIDADO', style: AppTextStyles.data(size: 12, line: 18).copyWith(color: city.onAccent)),
            ),
          ),
        ],
      ),
    );
    if (!animate) return seal;

    final drop = time.drive(CurveTween(curve: Interval(0, _at(AppMotion.stampDrop), curve: AppMotion.curveStamp)));
    final waveStart = _at(AppMotion.shockwaveDelay);
    final wave = time.drive(CurveTween(
      curve: Interval(waveStart, waveStart + _at(AppMotion.shockwave), curve: AppMotion.curve),
    ));

    return AnimatedBuilder(
      animation: time,
      child: seal,
      builder: (context, child) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (wave.value > 0 && wave.value < 1)
            Transform.scale(
              scale: 1 + 0.7 * wave.value,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: city.accent.withValues(alpha: 0.9 * (1 - wave.value)), width: 3),
                ),
              ),
            ),
          Opacity(
            opacity: drop.value.clamp(0, 1).toDouble(),
            child: Transform.rotate(
              angle: -(1 - drop.value) * 16 * math.pi / 180,
              child: Transform.scale(scale: 1.9 - 0.9 * drop.value, child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _SealRingPainter extends CustomPainter {
  final Color color;

  const _SealRingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    paintDottedRing(
      canvas,
      center: size.center(Offset.zero),
      radius: size.width / 2 - 2,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4
        ..color = color,
      dash: 6,
      gap: 8,
    );
  }

  @override
  bool shouldRepaint(_SealRingPainter oldDelegate) => oldDelegate.color != color;
}

/// Confetti in the colors of the flag, drawn with one painter.
class _Confetti extends StatelessWidget {
  final Animation<double> time;

  const _Confetti({required this.time});

  @override
  Widget build(BuildContext context) {
    final city = CityTheme.of(context);
    final colors = [for (final band in city.flag) band.color, city.accent];

    return IgnorePointer(
      child: CustomPaint(key: const ValueKey('confetti'), painter: ConfettiPainter(time: time, colors: colors)),
    );
  }
}

/// Forty pieces that start after the stamp and fall turning.
class ConfettiPainter extends CustomPainter {
  final Animation<double> time;
  final List<Color> colors;

  ConfettiPainter({required this.time, required this.colors}) : super(repaint: time);

  static const int pieces = 40;
  static const Size _piece = Size(8, 13);

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7);
    final elapsed = time.value * AppMotion.validationHold.inMilliseconds;
    final base = AppMotion.celebration.inMilliseconds;

    for (var i = 0; i < pieces; i++) {
      final x = random.nextDouble() * size.width;
      final delay = AppMotion.confettiDelay.inMilliseconds + random.nextDouble() * 350;
      final length = base + random.nextDouble() * 900;
      final drift = (random.nextDouble() - 0.5) * 80;
      final turns = (360 + random.nextDouble() * 540) * math.pi / 180;
      final t = (elapsed - delay) / length;
      if (t <= 0 || t >= 1) continue;

      final eased = Curves.easeIn.transform(t) * 0.6 + t * 0.4;
      final color = colors[i % colors.length];
      canvas
        ..save()
        ..translate(x + drift * eased, -_piece.height + (size.height + _piece.height * 2) * eased)
        ..rotate(turns * eased);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: _piece.width, height: _piece.height),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, Paint()..color = color);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => oldDelegate.colors != colors;
}

/// The content of the rank celebration (4C).
class RankCelebration extends StatelessWidget {
  final int level;
  final String rankName;

  /// The place of the rank in the citizen's city.
  final CityLandmark? place;
  final int? points;

  const RankCelebration({super.key, required this.level, required this.rankName, this.place, this.points});

  @override
  Widget build(BuildContext context) {
    final city = CityTheme.of(context);
    final photo = place?.photo;
    final name = photo == null ? rankName : place!.title;
    final eyebrow = photo == null ? 'Nuevo rango · Nivel $level' : 'Nuevo rango · $rankName';

    final words = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FlagStripe(),
        const SizedBox(height: AppSpacing.sm),
        Text(eyebrow.toUpperCase(), style: AppTextStyles.eyebrow.copyWith(color: CityTheme.onVeil)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          name,
          style: (photo == null ? AppTextStyles.display : AppTextStyles.cityDisplay).copyWith(color: CityTheme.onVeil),
        ),
        if (points != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text('$points pts', style: AppTextStyles.data(size: 16, line: 24).copyWith(color: city.accent)),
        ],
        const SizedBox(height: AppSpacing.md),
        Text('Toca para cerrar', style: AppTextStyles.caption.copyWith(color: CityTheme.onVeil)),
      ],
    );

    return _SelfClosing(
      hold: AppMotion.rankHold,
      semanticLabel: '$eyebrow: $name${points == null ? '' : ', $points puntos'}',
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [
          if (photo != null) ...[
            Image(
              image: photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.35, 0.7, 1],
                  colors: [
                    city.veil.withValues(alpha: 0),
                    city.veil.withValues(alpha: 0.8),
                    city.veil.withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),
          ] else
            Align(
              alignment: const Alignment(0, -0.3),
              child: RankSeal(level: level, size: AppSizes.celebrationSeal),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.xl), child: words),
            ),
          ),
        ],
      ),
    );
  }
}

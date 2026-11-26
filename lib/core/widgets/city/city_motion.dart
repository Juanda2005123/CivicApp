import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/city_theme.dart';
import '../brand_seal.dart';

/// The motion of the app (docs/design/04-city-identity.md, section 6): one
/// helper per pattern, the same in every city. With "reduce motion" on, each one
/// becomes a 100 ms fade: nothing scales, turns or flies.

/// 1A, "the seal sinks": a button or card shrinks to 96 % while it is pressed
/// and comes back. It only listens to the pointer, so the tap still reaches
/// [child].
class PressScale extends StatefulWidget {
  final Widget child;

  /// A disabled control does not answer the finger.
  final bool enabled;

  const PressScale({super.key, required this.child, this.enabled = true});

  static const double pressedScale = 0.96;
  static const double _pressedOpacity = 0.7;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.micro ~/ 2,
  );
  Offset? _downAt;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent event) {
    if (!widget.enabled) return;
    _downAt = event.position;
    _controller.forward();
  }

  /// A quick tap still reaches the bottom before coming back.
  void _release() {
    if (_downAt == null) return;
    _downAt = null;
    _controller.forward().whenComplete(() {
      if (mounted && _downAt == null) _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceOf(context);

    return Listener(
      onPointerDown: _down,
      // Dragging to scroll is not a press.
      onPointerMove: (event) {
        final start = _downAt;
        if (start != null && (event.position - start).distance > kTouchSlop) _release();
      },
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: reduce
          ? FadeTransition(
              opacity: _controller.drive(Tween(begin: 1, end: PressScale._pressedOpacity)),
              child: widget.child,
            )
          : ScaleTransition(
              scale: _controller.drive(
                Tween<double>(begin: 1, end: PressScale.pressedScale).chain(CurveTween(curve: AppMotion.curve)),
              ),
              child: widget.child,
            ),
    );
  }
}

/// 5A, shared axis between screens: the old one leaves 24 dp to the left while
/// it fades, the new one comes from 30 dp to the right.
class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder();

  static const double enterOffset = 30;
  static const double exitOffset = 24;

  /// Shares of the transition: the old screen is gone at 200 ms, the new one
  /// starts at 60 ms.
  static const double _exitEnd = 200 / 320;
  static const double _enterStart = 60 / 320;
  static const double _reducedEnd = 100 / 320;

  @override
  Duration get transitionDuration => AppMotion.emphasized;

  @override
  Duration get reverseTransitionDuration => AppMotion.emphasized;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduceOf(context)) {
      return FadeTransition(
        opacity: animation.drive(CurveTween(curve: const Interval(0, _reducedEnd))),
        child: child,
      );
    }

    final enter = animation.drive(CurveTween(curve: const Interval(_enterStart, 1, curve: AppMotion.curve)));
    final exit = secondaryAnimation.drive(CurveTween(curve: const Interval(0, _exitEnd, curve: AppMotion.curve)));

    return AnimatedBuilder(
      animation: Listenable.merge([enter, exit]),
      child: child,
      builder: (context, child) => Opacity(
        opacity: (enter.value * (1 - exit.value)).clamp(0, 1).toDouble(),
        child: Transform.translate(
          offset: Offset(enterOffset * (1 - enter.value) - exitOffset * exit.value, 0),
          child: child,
        ),
      ),
    );
  }
}

/// 8D: keeps its place but stays invisible for [AppMotion.loadingDelay], so
/// work that ends sooner shows no indicator. Screen readers hear it at once.
class DelayedReveal extends StatefulWidget {
  final Widget child;

  const DelayedReveal({super.key, required this.child});

  @override
  State<DelayedReveal> createState() => _DelayedRevealState();
}

class _DelayedRevealState extends State<DelayedReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _delay = AnimationController(vsync: this, duration: AppMotion.loadingDelay)
    ..forward();

  @override
  void dispose() {
    _delay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _delay,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _delay.isCompleted ? 1 : 0,
        alwaysIncludeSemantics: true,
        child: child,
      ),
    );
  }
}

/// 2D, endorsing: the thumb jumps, a "+1" floats up, and the dotted ring around
/// it moves forward a tenth and beats. [count] of [target] endorsements fill
/// the ring; the animation runs when [count] goes up while [endorsed].
class EndorseThumb extends StatefulWidget {
  final IconData icon;
  final int count;
  final int target;
  final bool endorsed;

  /// Color of the icon and the ring, so it reads on the button that holds it.
  final Color color;

  /// Color of the "+1", which floats over the page.
  final Color burstColor;

  const EndorseThumb({
    super.key,
    required this.icon,
    required this.count,
    required this.target,
    required this.endorsed,
    required this.color,
    required this.burstColor,
  });

  @override
  State<EndorseThumb> createState() => _EndorseThumbState();
}

class _EndorseThumbState extends State<EndorseThumb> with TickerProviderStateMixin {
  late final AnimationController _jump = AnimationController(vsync: this, duration: AppMotion.thumbJump);
  late final AnimationController _beat = AnimationController(vsync: this, duration: AppMotion.ringBeat);
  late final AnimationController _burst = AnimationController(vsync: this, duration: AppMotion.floatUp);

  @override
  void didUpdateWidget(EndorseThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    final added = widget.endorsed && !oldWidget.endorsed && widget.count > oldWidget.count;
    if (added && !AppMotion.reduceOf(context)) {
      _jump.forward(from: 0);
      _beat.forward(from: 0);
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _jump.dispose();
    _beat.dispose();
    _burst.dispose();
    super.dispose();
  }

  /// 0 → 1 → 0 over the animation: how far from rest the thumb or the ring is.
  static double _there(double t) => math.sin(math.pi * AppMotion.curveStamp.transform(t).clamp(0, 1));

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reduceOf(context);
    final fraction = widget.target == 0 ? 0.0 : (widget.count / widget.target).clamp(0.0, 1.0);

    return SizedBox.square(
      dimension: AppSizes.endorseRing,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _beat,
            builder: (context, child) => Transform.scale(scale: 1 + 0.22 * _there(_beat.value), child: child),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: fraction, end: fraction),
              duration: reduce ? AppMotion.reduced : AppMotion.ringBeat,
              curve: AppMotion.curve,
              builder: (context, value, _) => CustomPaint(
                size: const Size.square(AppSizes.endorseRing),
                painter: _EndorseRingPainter(color: widget.color, fraction: value),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _jump,
            builder: (context, child) {
              final out = _there(_jump.value);
              return Transform.rotate(
                angle: -out * math.pi / 15, // -12°
                child: Transform.scale(scale: 1 + 0.45 * out, child: child),
              );
            },
            child: Icon(widget.icon, size: AppSizes.icon - 2, color: widget.color),
          ),
          Positioned(
            bottom: AppSizes.endorseRing - AppSpacing.sm,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (context, _) {
                    if (!_burst.isAnimating) return const SizedBox.shrink();
                    final t = AppMotion.curve.transform(_burst.value);
                    return Transform.translate(
                      offset: Offset(0, -AppSpacing.xxl * t),
                      child: Opacity(
                        opacity: 1 - t,
                        child: Text(
                          '+1',
                          style: AppTextStyles.data(size: 14).copyWith(color: widget.burstColor),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dotted track plus the arc already earned.
class _EndorseRingPainter extends CustomPainter {
  final Color color;
  final double fraction;

  const _EndorseRingPainter({required this.color, required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    Paint stroke(Color color, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width
      ..color = color;

    paintDottedRing(canvas, center: center, radius: radius, paint: stroke(color.withValues(alpha: 0.35), 1.5), dash: 2, gap: 3);
    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        stroke(color, 2.5),
      );
    }
  }

  @override
  bool shouldRepaint(_EndorseRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fraction != fraction;
}

/// 7A, changing city: the stripes of the new city's flag sweep across the screen
/// and leave. It covers while [progress] goes through [FlagCurtain.coverShare]
/// and uncovers afterwards; the page underneath changes while it is covered.
class FlagCurtain extends StatelessWidget {
  final List<CityFlagBand> flag;
  final Animation<double> progress;

  const FlagCurtain({super.key, required this.flag, required this.progress});

  /// Time the screen stays fully covered between the two sweeps.
  static const Duration hold = Duration(milliseconds: 40);

  static Duration get duration => AppMotion.curtainIn + hold + AppMotion.curtainOut;

  /// Share of [duration] after which the screen is fully covered.
  static double get coverShare => AppMotion.curtainIn.inMicroseconds / duration.inMicroseconds;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(painter: _CurtainPainter(flag: flag, progress: progress), size: Size.infinite),
      ),
    );
  }
}

class _CurtainPainter extends CustomPainter {
  final List<CityFlagBand> flag;
  final Animation<double> progress;

  _CurtainPainter({required this.flag, required this.progress}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cover = FlagCurtain.coverShare;
    final uncover = 1 - AppMotion.curtainOut.inMicroseconds / FlagCurtain.duration.inMicroseconds;
    final t = progress.value;
    final right = t >= cover ? 1.0 : Curves.easeIn.transform(t / cover);
    final left = t <= uncover ? 0.0 : AppMotion.curve.transform((t - uncover) / (1 - uncover));
    if (right <= left) return;

    canvas.clipRect(Rect.fromLTRB(left * size.width, 0, right * size.width, size.height));
    final total = flag.fold<int>(0, (sum, band) => sum + band.weight);
    var top = 0.0;
    for (final band in flag) {
      final height = size.height * band.weight / total;
      // One extra pixel so no seam shows between stripes.
      canvas.drawRect(Rect.fromLTWH(0, top, size.width, height + 1), Paint()..color = band.color);
      top += height;
    }
  }

  @override
  bool shouldRepaint(_CurtainPainter oldDelegate) => oldDelegate.flag != flag;
}

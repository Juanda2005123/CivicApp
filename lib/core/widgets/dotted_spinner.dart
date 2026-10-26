import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand_seal.dart';

/// Loading indicator of the design system: a dotted ring that rotates. With
/// "reduce motion" on, the ring stays still.
class DottedSpinner extends StatefulWidget {
  final double size;
  final Color? color;
  final String semanticLabel;

  const DottedSpinner({super.key, this.size = 24, this.color, this.semanticLabel = 'Cargando'});

  @override
  State<DottedSpinner> createState() => _DottedSpinnerState();
}

class _DottedSpinnerState extends State<DottedSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
    final color = widget.color ?? Theme.of(context).colorScheme.onSurface;

    return Semantics(
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: CustomPaint(painter: _RingPainter(color)),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color color;

  const _RingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    paintDottedRing(
      canvas,
      center: const Offset(32, 32),
      radius: 26,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = color,
      dash: 6,
      gap: 9,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.color != color;
}

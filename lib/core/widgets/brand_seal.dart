import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Draws a dotted ring (the "perforation" of the seal) of [radius] around [center].
///
/// The dash count is rounded so the pattern closes evenly. Shared by the seal,
/// the rank seals, the spinner and the backdrop.
void paintDottedRing(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required Paint paint,
  double dash = 2,
  double gap = 3,
}) {
  final circumference = 2 * math.pi * radius;
  final count = math.max(1, (circumference / (dash + gap)).round());
  final step = 2 * math.pi / count;
  final sweep = step * dash / (dash + gap);
  final rect = Rect.fromCircle(center: center, radius: radius);
  for (var i = 0; i < count; i++) {
    canvas.drawArc(rect, i * step, sweep, false, paint);
  }
}

enum SealVariant {
  /// Picks [filled] on light themes and [onDark] on dark themes.
  auto,

  /// Ink disc with cream details: for light backgrounds.
  filled,

  /// Cream outline without disc: for ink or dark backgrounds.
  onDark,
}

/// The VIGÍA seal: dotted ring, a V, a mustard dot above and a clay dot below.
/// Same geometry as `docs/design/assets/logo/vigia-seal.svg` (64 x 64 space).
class BrandSeal extends StatelessWidget {
  final double size;
  final SealVariant variant;

  const BrandSeal({super.key, this.size = 72, this.variant = SealVariant.auto});

  @override
  Widget build(BuildContext context) {
    final onDark = switch (variant) {
      SealVariant.filled => false,
      SealVariant.onDark => true,
      SealVariant.auto => Theme.of(context).brightness == Brightness.dark,
    };
    return Semantics(
      label: 'VIGÍA',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _SealPainter(onDark: onDark)),
        ),
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  final bool onDark;

  const _SealPainter({required this.onDark});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    const center = Offset(32, 32);

    if (onDark) {
      canvas.drawCircle(
        center,
        30,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = AppColors.cream,
      );
    } else {
      canvas.drawCircle(center, 30, Paint()..color = AppColors.ink);
    }

    paintDottedRing(
      canvas,
      center: center,
      radius: 25.5,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.cream,
    );

    final v = Path()
      ..moveTo(19, 21)
      ..lineTo(26, 21)
      ..lineTo(32, 36)
      ..lineTo(38, 21)
      ..lineTo(45, 21)
      ..lineTo(35, 47)
      ..lineTo(29, 47)
      ..close();
    canvas.drawPath(v, Paint()..color = AppColors.cream);

    canvas.drawCircle(const Offset(32, 13), 2.6, Paint()..color = AppColors.mustard);
    canvas.drawCircle(const Offset(32, 51), 1.6, Paint()..color = AppColors.clay500);
  }

  @override
  bool shouldRepaint(_SealPainter oldDelegate) => oldDelegate.onDark != onDark;
}

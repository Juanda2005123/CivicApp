import 'package:flutter/material.dart';

import 'brand_seal.dart';

/// Page background: the theme's surface color with the brand pattern (cropped
/// dotted rings, 8 % opacity) in the top-right corner. No photos, no blur.
class BrandBackdrop extends StatelessWidget {
  final Widget child;

  const BrandBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    return Stack(
      children: [
        Positioned(
          top: -90,
          right: -90,
          width: 260,
          height: 260,
          child: IgnorePointer(
            child: ExcludeSemantics(child: CustomPaint(painter: _RingsPainter(color))),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  final Color color;

  const _RingsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color;
    for (final radius in const [96.0, 74.0, 52.0, 30.0]) {
      paintDottedRing(
        canvas,
        center: const Offset(100, 100),
        radius: radius,
        paint: paint,
        dash: 4,
        gap: 7,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) => oldDelegate.color != color;
}

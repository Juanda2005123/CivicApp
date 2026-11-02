import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'brand_seal.dart';

/// Seal of a civic rank (RN-09): level 1 to 4, each one fuller and more
/// "official" than the last. See the design document, section 3.4.
class RankSeal extends StatelessWidget {
  final int level;
  final double size;

  /// Spoken label, for example "Nivel 1, Observador Urbano".
  final String? semanticLabel;

  const RankSeal({super.key, required this.level, this.size = 64, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final lv = level.clamp(1, 4);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final numeralColor = lv == 3 ? AppColors.ink : AppColors.cream;

    return Semantics(
      label: semanticLabel ?? 'Nivel $lv',
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: Size.square(size), painter: _RankPainter(level: lv, dark: dark)),
              Text(
                '$lv',
                style: AppTextStyles.numeral(size * (lv == 4 ? 0.41 : 0.47)).copyWith(color: numeralColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankPainter extends CustomPainter {
  final int level;
  final bool dark;

  const _RankPainter({required this.level, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    const center = Offset(32, 32);

    Paint stroke(Color color, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color;

    switch (level) {
      case 1:
        if (dark) {
          canvas.drawCircle(center, 30, Paint()..color = AppColors.inkDeep);
          canvas.drawCircle(center, 30, stroke(AppColors.cream, 1.2));
        } else {
          canvas.drawCircle(center, 30, Paint()..color = AppColors.ink);
        }
        paintDottedRing(canvas, center: center, radius: 25.5, paint: stroke(AppColors.cream, 1.5));
      case 2:
        canvas.drawCircle(center, 30, Paint()..color = AppColors.sage700);
        paintDottedRing(canvas, center: center, radius: 25.5, paint: stroke(AppColors.cream, 1.5));
      case 3:
        canvas.drawCircle(center, 30, Paint()..color = AppColors.mustard);
        canvas.drawCircle(center, 25.5, stroke(AppColors.ink, 1.8));
      default:
        canvas.drawCircle(center, 30, Paint()..color = AppColors.clay700);
        canvas.drawCircle(center, 26.5, stroke(AppColors.cream, 1.6));
        paintDottedRing(canvas, center: center, radius: 22.5, paint: stroke(AppColors.cream, 1.2));
    }
  }

  @override
  bool shouldRepaint(_RankPainter oldDelegate) =>
      oldDelegate.level != level || oldDelegate.dark != dark;
}

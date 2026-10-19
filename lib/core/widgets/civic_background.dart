import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Apple Light Mode organic diffuse aurora background with architectural
/// infrastructure photographic backdrop.
/// Follows aurora.md: non-interactive, behind content, pointer-events-none equivalent,
/// smooth radial gradients with light/dark parity.
class CivicBackground extends StatelessWidget {
  final Widget child;
  final bool showHeroImage;

  const CivicBackground({
    super.key,
    required this.child,
    this.showHeroImage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Base light canvas
        Positioned.fill(
          child: Container(color: AppTheme.background),
        ),

        // 2. Ambient Photographic Infrastructure Backdrop
        if (showHeroImage)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: IgnorePointer(
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Color(0x99000000),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/images/civic_road_hero.jpg',
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.25),
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
          ),

        // 3. Light Aurora layer — organic, non-interactive diffuse glows
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LightAuroraPainter(),
            ),
          ),
        ),

        // 4. Content
        Positioned.fill(child: child),
      ],
    );
  }
}

class _LightAuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Top-right soft indigo / blue organic glow
    final indigoPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6366F1).withValues(alpha: 0.10),
          const Color(0xFF818CF8).withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.1),
          radius: size.width * 0.75,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.1),
      size.width * 0.75,
      indigoPaint,
    );

    // 2. Bottom-left soft sky / cyan organic glow
    final skyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0EA5E9).withValues(alpha: 0.07),
          const Color(0xFF38BDF8).withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.1, size.height * 0.85),
          radius: size.width * 0.65,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.85),
      size.width * 0.65,
      skyPaint,
    );

    // 3. Top-left delicate rose organic glow
    final rosePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF43F5E).withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.15, size.height * 0.2),
          radius: size.width * 0.5,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.2),
      size.width * 0.5,
      rosePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Frosted Glassmorphic container card implementing glass.md standards.
/// Pure Apple Light frosted glass: BackdropFilter blur, translucent white fill,
/// top specular reflection rim, and physical micro-shadows.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;

  const GlassCard({
    super.key,
    required this.child,
    this.maxWidth = 480.0,
    this.padding,
    this.blurSigma = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              width: double.infinity,
              padding: padding ?? const EdgeInsets.all(28.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.95),
                  width: 1.5,
                ),
                boxShadow: const [
                  // Ambient diffuse depth
                  BoxShadow(
                    color: Color(0x0E0F172A),
                    blurRadius: 36,
                    offset: Offset(0, 14),
                    spreadRadius: -2,
                  ),
                  // Direct micro contact shadow
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle top specular highlight band
                  Positioned(
                    top: 0,
                    left: 20,
                    right: 20,
                    height: 1.5,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

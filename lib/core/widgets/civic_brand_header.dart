import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Apple Liquid Glass Brand Header for VIGÍA.
/// Features a liquid glass orb with specular reflections, a civic pill badge,
/// and precise typography.
/// Preserves exact test target strings ('VIGÍA', 'Civic Road Infrastructure Auditing Platform').
class CivicBrandHeader extends StatelessWidget {
  final bool compact;
  final String? subtitle;

  const CivicBrandHeader({
    super.key,
    this.compact = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Floating Liquid Glass Civic Pill Badge
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.95),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A4F46E5),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'VEEDURÍA VIAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        // 2. Liquid Glass Orb (Multi-layer specular lens container)
        Container(
          width: compact ? 54 : 64,
          height: compact ? 54 : 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEEF2FF), // Indigo 50
                Color(0xFFE0E7FF), // Indigo 100
                Color(0xFFC7D2FE), // Indigo 200
              ],
            ),
            border: Border.all(
              color: Colors.white,
              width: 2.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x224F46E5),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Upper specular highlight reflection
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: (compact ? 54 : 64) * 0.48,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.65),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Icon
              Center(
                child: Icon(
                  Icons.remove_red_eye_rounded,
                  size: compact ? 26 : 32,
                  color: AppTheme.accent,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 12 : 18),

        // 3. Brand Name — exact test match: 'VIGÍA'
        const Text(
          'VIGÍA',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 4.0,
            color: AppTheme.textPrimary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),

        // 4. Subtitle — exact test match: 'Civic Road Infrastructure Auditing Platform'
        Text(
          subtitle ?? 'Civic Road Infrastructure Auditing Platform',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppTheme.textMuted,
            letterSpacing: 0.1,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

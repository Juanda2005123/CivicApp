import 'dart:ui';
import 'package:flutter/material.dart';

/// Authentic Apple iOS / VisionOS Liquid Glass Button.
/// Pure monochromatic liquid glass: deep obsidian liquid glass core,
/// upper specular lens refraction, razor-thin specular highlight rim,
/// and natural ambient glass occlusion shadow. Absolutely zero blue.
class LiquidGlassButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double borderRadius;
  final List<Color>? fluidColors;

  const LiquidGlassButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.height = 52.0,
    this.borderRadius = 16.0,
    this.fluidColors,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    // Apple Monochrome Obsidian Liquid Glass (Zero blue)
    final defaultObsidianColors = [
      const Color(0xFF27272A), // Zinc 800 (Top specular reflection)
      const Color(0xFF18181B), // Zinc 900 (Core obsidian glass)
      const Color(0xFF09090B), // Zinc 950 (Deep liquid refraction)
    ];

    final colors = widget.fluidColors ?? defaultObsidianColors;

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: enabled
              ? const [
                  // Ambient neutral liquid depth shadow (No blue)
                  BoxShadow(
                    color: Color(0x38000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                    spreadRadius: -2,
                  ),
                  // Direct micro contact shadow
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Obsidian Liquid Core
              Container(
                decoration: BoxDecoration(
                  gradient: enabled
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: colors,
                          stops: const [0.0, 0.45, 1.0],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                        ),
                ),
              ),

              // 2. Liquid Glass Backdrop Filter for physical refraction
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Colors.white.withValues(alpha: enabled ? 0.04 : 0.08),
                ),
              ),

              // 3. Upper Specular Lens Reflection (Glossy curved half-lens)
              if (enabled)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: widget.height * 0.50,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Liquid Glass Perimeter Border
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: enabled
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                ),
              ),

              // 5. Razor-thin Top Specular Highlight Rim (Overhead light bounce)
              if (enabled)
                Positioned(
                  top: 0,
                  left: widget.borderRadius * 0.6,
                  right: widget.borderRadius * 0.6,
                  height: 1.2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // 6. Interactive Material Layer & Content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: enabled ? widget.onPressed : null,
                  onHighlightChanged: (val) => setState(() => _isPressed = val),
                  splashColor: Colors.white.withValues(alpha: 0.15),
                  highlightColor: Colors.white.withValues(alpha: 0.08),
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.label,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

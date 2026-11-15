import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/severity_colors.dart';
import '../../../reports/domain/entities/incident.dart';

/// Map marker of a report (design system section 6, "Mapa"): the **shape** and
/// color come from the severity, the icon from the category, so color is never
/// the only signal. The tap target is 48 dp even though the shape is smaller.
class IncidentMapMarker extends StatelessWidget {
  final IncidentSeverity severity;
  final String categoryIcon;
  final String semanticLabel;
  final VoidCallback onTap;

  const IncidentMapMarker({
    super.key,
    required this.severity,
    required this.categoryIcon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.severity;
    final (fill, onFill) = switch (severity) {
      IncidentSeverity.low => (colors.low, colors.onLow),
      IncidentSeverity.medium => (colors.medium, colors.onMedium),
      IncidentSeverity.high => (colors.high, colors.onHigh),
      IncidentSeverity.critical => (colors.critical, colors.onCritical),
    };
    // The triangle's visual center sits lower than the box center.
    final iconOffset = severity == IncidentSeverity.medium ? AppSpacing.xs : 0.0;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: AppSizes.touchTarget,
          child: Center(
            child: CustomPaint(
              painter: _SeverityShapePainter(
                severity: severity,
                fill: fill,
                outline: colors.markerOutline,
              ),
              child: SizedBox.square(
                dimension: markerSize,
                child: Padding(
                  padding: EdgeInsets.only(top: iconOffset),
                  child: Icon(categoryIconData(categoryIcon), size: AppSizes.icon - 2, color: onFill),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Size of the drawn shape, inside the 48 dp tap target.
  static const double markerSize = 36;
}

/// Icon of a category from the key stored in `incident_category.icon`.
IconData categoryIconData(String key) => switch (key) {
      'warning' => Icons.remove_road_outlined,
      'traffic' => Icons.traffic_outlined,
      'construction' => Icons.construction_outlined,
      'directions_walk' => Icons.directions_walk_outlined,
      'water_drop' => Icons.water_drop_outlined,
      'signpost' => Icons.signpost_outlined,
      _ => Icons.report_problem_outlined,
    };

/// Draws the severity shape: circle (low), triangle (medium), diamond (high),
/// octagon like a stop sign (critical).
class _SeverityShapePainter extends CustomPainter {
  final IncidentSeverity severity;
  final Color fill;
  final Color outline;

  _SeverityShapePainter({required this.severity, required this.fill, required this.outline});

  static const double _outlineWidth = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_outlineWidth / 2);
    final path = switch (severity) {
      IncidentSeverity.low => Path()..addOval(rect),
      IncidentSeverity.medium => Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close(),
      IncidentSeverity.high => Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.center.dy)
        ..lineTo(rect.center.dx, rect.bottom)
        ..lineTo(rect.left, rect.center.dy)
        ..close(),
      IncidentSeverity.critical => _octagon(rect),
    };

    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outlineWidth
        ..strokeJoin = StrokeJoin.round,
    );
  }

  static Path _octagon(Rect rect) {
    final radius = rect.width / 2;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = pi / 8 + i * pi / 4;
      final point = rect.center + Offset(cos(angle), sin(angle)) * radius;
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_SeverityShapePainter old) =>
      old.severity != severity || old.fill != fill || old.outline != outline;
}

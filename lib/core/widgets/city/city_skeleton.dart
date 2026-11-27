import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'city_motion.dart';

/// What is loading: the skeleton has the shape of the cards that will arrive.
enum CitySkeletonShape {
  /// Report cards of Comunidad.
  feed,

  /// Identity, rank climb and counters of "Mi perfil".
  profile,

  /// The impact panel inside "Mi perfil": climb, counters and "Mis reportes".
  impact,

  /// Code, photo, validation and text of a report.
  detail,

  /// Short rows with a round avatar (comments).
  list,
}

/// 8D: the first load of a list or screen without data draws grey shapes with a
/// shine passing over them. It appears after [DelayedReveal]'s 300 ms, so a fast
/// answer shows nothing. With "reduce motion" the shapes stay still.
class CitySkeleton extends StatefulWidget {
  final CitySkeletonShape shape;

  /// What screen readers hear ("Cargando los reportes").
  final String semanticLabel;

  /// Whether the skeleton fills a screen (it then clips what does not fit) or
  /// sits inside a page that already scrolls.
  final bool fill;

  const CitySkeleton({super.key, required this.shape, required this.semanticLabel, this.fill = true});

  @override
  State<CitySkeleton> createState() => _CitySkeletonState();
}

class _CitySkeletonState extends State<CitySkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(vsync: this, duration: AppMotion.shimmer);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceOf(context)) {
      _shine.stop();
    } else if (!_shine.isAnimating) {
      _shine.repeat();
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bone = scheme.onSurface.withValues(alpha: 0.1);
    final shine = scheme.onSurface.withValues(alpha: 0.04);

    Widget body = Padding(
      padding: widget.fill ? const EdgeInsets.all(AppSpacing.lg) : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _blocks(context, bone),
      ),
    );

    if (!AppMotion.reduceOf(context)) {
      body = AnimatedBuilder(
        animation: _shine,
        child: body,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            colors: [shine.withValues(alpha: 0), shine, scheme.surface.withValues(alpha: 0.65), shine.withValues(alpha: 0)],
            stops: const [0.3, 0.45, 0.5, 0.7],
            transform: _Slide(_shine.value * 2 - 1),
          ).createShader(bounds),
          child: child,
        ),
      );
    }

    return Semantics(
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: DelayedReveal(
          child: widget.fill
              ? SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: body)
              : body,
        ),
      ),
    );
  }

  List<Widget> _blocks(BuildContext context, Color bone) {
    const gap = SizedBox(height: AppSpacing.md);

    Widget box({double? width, double height = AppSizes.skeletonLine, bool round = false}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: bone,
            shape: round ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: round ? null : AppRadii.small,
          ),
        );

    // A card with the border of the real ones.
    Widget card(Widget child) => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadii.medium,
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: child,
        );

    Widget lines(List<double> widths) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (index, share) in widths.indexed) ...[
              if (index > 0) const SizedBox(height: AppSpacing.sm),
              FractionallySizedBox(widthFactor: share, child: box()),
            ],
          ],
        );

    Widget row(Widget lead, List<double> widths) => card(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [lead, const SizedBox(width: AppSpacing.md), Expanded(child: lines(widths))],
        ));

    Widget report() => row(
          box(width: AppSizes.skeletonThumbnail, height: AppSizes.skeletonThumbnail),
          [0.9, 0.55, 0.4],
        );

    Widget medalRow() => Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Row(
            children: [
              box(width: AppSizes.medal, height: AppSizes.medal, round: true),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: lines([0.6, 0.35])),
            ],
          ),
        );

    final climb = card(Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [lines([0.45, 0.7]), gap, box(height: AppSpacing.sm), medalRow(), medalRow()],
    ));

    Widget counters() => Row(
          children: [
            Expanded(child: card(lines([0.3, 0.8]))),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: card(lines([0.3, 0.8]))),
          ],
        );

    return switch (widget.shape) {
      CitySkeletonShape.feed => [report(), gap, report(), gap, report(), gap, report()],
      CitySkeletonShape.profile => [
          row(box(width: AppSizes.medal, height: AppSizes.medal, round: true), [0.7, 0.4, 0.5]),
          gap,
          climb,
          gap,
          counters(),
        ],
      CitySkeletonShape.impact => [climb, gap, counters(), gap, report()],
      CitySkeletonShape.detail => [
          card(lines([0.4, 0.6])),
          gap,
          box(height: AppSizes.skeletonPhoto),
          gap,
          card(Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [lines([0.7]), gap, box(height: AppSpacing.sm)],
          )),
          gap,
          box(height: AppSizes.button),
          gap,
          card(lines([0.8, 1, 0.9, 0.6])),
        ],
      CitySkeletonShape.list => [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) gap,
            row(box(width: AppSizes.chip, height: AppSizes.chip, round: true), [0.4, 0.9]),
          ],
        ],
    };
  }
}

/// Moves a gradient across its bounds: -1 before them, 1 after them.
class _Slide extends GradientTransform {
  final double share;

  const _Slide(this.share);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * share, 0, 0);
}

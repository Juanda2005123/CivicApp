import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/city_theme.dart';
import 'flag_stripe.dart';

/// The header of a city: its photo of this moment of the day under the veil, the
/// flag, the greeting and the slogan, with the slow zoom (6A). Looks without
/// photos draw nothing.
///
/// There is one controller for the zoom. It rests with "reduce motion", when the
/// header is scrolled out of view, and in hidden tabs or covered screens (their
/// ticker is muted). The short header is still.
class CityHero extends StatefulWidget {
  /// Shorter, still header without the greeting, for the login.
  final bool compact;

  const CityHero({super.key, this.compact = false});

  @override
  State<CityHero> createState() => _CityHeroState();
}

class _CityHeroState extends State<CityHero> with SingleTickerProviderStateMixin {
  static const double _zoom = 1.1;

  late final AnimationController _ambient = AnimationController(vsync: this, duration: AppMotion.ambient);
  ScrollPosition? _scroll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (scroll != _scroll) {
      _scroll?.removeListener(_updateZoom);
      _scroll = scroll?..addListener(_updateZoom);
    }
    _updateZoom();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_updateZoom);
    _ambient.dispose();
    super.dispose();
  }

  double get _height => widget.compact ? AppSizes.cityHeroCompact : AppSizes.cityHero;

  /// The header is the first thing of its scroll view, so it is out of sight once
  /// the view moved further than its height.
  bool get _scrolledOut {
    final scroll = _scroll;
    return scroll != null && scroll.hasPixels && scroll.pixels >= _height;
  }

  void _updateZoom() {
    if (!mounted) return;
    final city = CityTheme.of(context);
    final move = !widget.compact && city.hero != null && !AppMotion.reduceOf(context) && !_scrolledOut;

    if (!move) {
      _ambient.stop();
      if (AppMotion.reduceOf(context)) _ambient.value = 0;
    } else if (!_ambient.isAnimating) {
      _ambient.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final city = CityTheme.of(context);
    final photo = city.hero;
    if (photo == null) return const SizedBox.shrink();

    final zoom = _ambient.drive(CurveTween(curve: Curves.easeInOut));

    return ClipRect(
      child: ColoredBox(
        color: city.veil,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: zoom,
                builder: (context, child) => Transform.scale(
                  scale: 1 + (_zoom - 1) * zoom.value,
                  alignment: Alignment(0.2 * zoom.value, 0.1 * zoom.value),
                  child: child,
                ),
                child: Image(
                  image: photo,
                  fit: BoxFit.cover,
                  semanticLabel: city.heroDescription,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            // The veil: solid at the bottom, where the text is, so it passes AA.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.32, 0.72, 1],
                    colors: [
                      city.veil.withValues(alpha: 0.55),
                      city.veil.withValues(alpha: 0.1),
                      city.veil.withValues(alpha: 0.78),
                      city.veil.withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
            ),
            // The text sizes the header when it is taller than the photo (200 %).
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: _height, minWidth: double.infinity),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxxl, AppSpacing.lg, AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _texts(city),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _texts(CityTheme city) {
    // The login only names the place; the feed also says when.
    final place = widget.compact
        ? '${city.displayName}, ${city.department}'
        : '${city.displayName}, ${city.department} · ${city.dayPart.labelSpanish}';

    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FlagStripe(),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              place.toUpperCase(),
              semanticsLabel: place,
              style: AppTextStyles.eyebrow.copyWith(color: CityTheme.onVeil),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      if (widget.compact)
        Text(city.copy.slogan, style: AppTextStyles.bodyStrong.copyWith(color: CityTheme.onVeil))
      else ...[
        Semantics(
          header: true,
          child: Text(city.copy.greeting, style: AppTextStyles.cityHeadline.copyWith(color: CityTheme.onVeil)),
        ),
        Text(city.copy.slogan, style: AppTextStyles.bodySmall.copyWith(color: CityTheme.onVeil)),
      ],
    ];
  }
}

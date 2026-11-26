import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/city_theme.dart';
import '../../utils/search_text.dart';
import '../rank_seal.dart';
import 'flag_stripe.dart';

/// One civic rank of the ladder, as the database defines it (RN-09).
@immutable
class TrailRank {
  final int level;
  final String name;

  /// Points that earn it; null when the screen does not know them.
  final int? minXp;

  const TrailRank({required this.level, required this.name, this.minXp});

  /// The place the city gives to this rank: by name, else by its position.
  CityLandmark? landmarkIn(List<CityLandmark> landmarks) {
    final wanted = normalizeSearchText(name);
    for (final landmark in landmarks) {
      if (normalizeSearchText(landmark.rankName) == wanted) return landmark;
    }
    final index = level - 1;
    return index >= 0 && index < landmarks.length ? landmarks[index] : null;
  }
}

/// The citizen's climb (RN-09, HU-23): the progress to the next rank and the
/// four ranks, each with the place their city gives it, bottom to top, with a
/// "TÚ" mark where they stand. Without city photos the rank seals stand in.
class LandmarkTrail extends StatelessWidget {
  /// The whole ladder, lowest rank first.
  final List<TrailRank> ranks;
  final int currentLevel;

  /// Heading of the card ("Tu avance").
  final String title;

  /// Progress to the next rank, from 0 to 1, and its two lines of text.
  final double progress;
  final String points;
  final String caption;

  /// Put on the medal of the current rank, where the rank celebration opens.
  final Key? currentMedalKey;

  const LandmarkTrail({
    super.key,
    required this.ranks,
    required this.currentLevel,
    required this.title,
    required this.progress,
    required this.points,
    required this.caption,
    this.currentMedalKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final city = CityTheme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final percent = (progress * 100).round();
    final current = ranks.where((rank) => rank.level == currentLevel).firstOrNull;
    final currentPlace = current?.landmarkIn(city.landmarks);
    final hasPhotos = currentPlace?.medal != null;
    final highest = ranks.isNotEmpty && ranks.last.level == currentLevel;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasPhotos)
            _CityHeading(
              title: title,
              climbTitle: city.copy.climbTitle,
              headline: highest ? 'Llegaste a ${currentPlace!.title}' : 'Vas por ${currentPlace!.title}',
              level: 'Nivel actual: $currentLevel',
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Row(
                children: [
                  RankSeal(
                    level: currentLevel,
                    size: AppSizes.buttonCompact,
                    semanticLabel: 'Nivel $currentLevel, ${current?.name ?? ''}',
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        Text('Nivel actual: $currentLevel', style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: 'Progreso hacia el siguiente nivel',
                  value: '$percent por ciento',
                  child: ExcludeSemantics(
                    child: ClipRRect(
                      borderRadius: AppRadii.small,
                      child: LinearProgressIndicator(value: progress, minHeight: AppSpacing.sm - 2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(points, style: AppTextStyles.data(size: 14, line: 20)),
                const SizedBox(height: AppSpacing.xs),
                Text(caption, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: Column(
              children: [
                // The summit first, the start at the bottom.
                for (final rank in ranks.reversed)
                  _Stop(
                    rank: rank,
                    place: rank.landmarkIn(city.landmarks),
                    state: rank.level < currentLevel
                        ? _StopState.passed
                        : rank.level == currentLevel
                            ? _StopState.current
                            : rank.level == currentLevel + 1
                                ? _StopState.next
                                : _StopState.ahead,
                    isTop: rank == ranks.last,
                    isBottom: rank == ranks.first,
                    medalKey: rank.level == currentLevel ? currentMedalKey : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Header on the city's veil: where the climb goes and where the citizen is.
class _CityHeading extends StatelessWidget {
  final String title;
  final String climbTitle;
  final String headline;
  final String level;

  const _CityHeading({required this.title, required this.climbTitle, required this.headline, required this.level});

  @override
  Widget build(BuildContext context) {
    final city = CityTheme.of(context);
    final small = Theme.of(context).textTheme.bodySmall?.copyWith(color: CityTheme.onVeil);

    return ColoredBox(
      color: city.veil,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const FlagStripe(),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    climbTitle.toUpperCase(),
                    semanticsLabel: climbTitle,
                    style: AppTextStyles.eyebrow.copyWith(color: CityTheme.onVeil),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Semantics(
              header: true,
              child: Text(headline, style: AppTextStyles.cityTitle.copyWith(color: CityTheme.onVeil)),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(title, style: small?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(level, style: small)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _StopState { passed, current, next, ahead }

class _Stop extends StatelessWidget {
  final TrailRank rank;
  final CityLandmark? place;
  final _StopState state;
  final bool isTop;
  final bool isBottom;
  final Key? medalKey;

  const _Stop({
    required this.rank,
    required this.place,
    required this.state,
    required this.isTop,
    required this.isBottom,
    this.medalKey,
  });

  bool get _earned => state == _StopState.passed || state == _StopState.current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final city = CityTheme.of(context);
    final scheme = theme.colorScheme;
    // A place with a photo is named after the place; otherwise after the rank.
    final hasPhoto = place?.medal != null;
    final name = hasPhoto ? place!.title : rank.name;
    final detail = [
      if (rank.minXp != null) '${rank.minXp} XP',
      if (hasPhoto) rank.name,
    ].join(' · ');
    final tag = switch (state) {
      _StopState.current => 'Logrado',
      _StopState.next => 'Siguiente',
      _ => null,
    };
    final spoken = [
      name,
      detail,
      _earned ? 'logrado' : 'pendiente',
      if (state == _StopState.current) 'aquí vas',
    ].where((part) => part.isNotEmpty).join(', ');

    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: CustomPaint(
        painter: _PathPainter(
          color: scheme.onSurface.withValues(alpha: 0.35),
          above: !isTop,
          below: !isBottom,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              SizedBox(
                key: medalKey,
                width: AppSizes.medal,
                height: AppSizes.medal,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    _medal(context),
                    if (state == _StopState.current)
                      Positioned(
                        bottom: -AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: city.accent,
                            borderRadius: BorderRadius.circular(AppRadii.chip),
                            border: Border.all(color: scheme.surfaceContainerLow, width: 2),
                          ),
                          child: Text(
                            'TÚ',
                            style: AppTextStyles.data(size: 10, line: 14).copyWith(color: city.onAccent),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(name, style: theme.textTheme.titleSmall),
                        if (tag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm - 2),
                            decoration: BoxDecoration(color: city.deep, borderRadius: AppRadii.small),
                            child: Text(
                              tag.toUpperCase(),
                              style: AppTextStyles.data(size: 10, line: 16).copyWith(color: city.onDeep),
                            ),
                          ),
                      ],
                    ),
                    if (detail.isNotEmpty)
                      Text(
                        detail,
                        style: AppTextStyles.data(size: 11, line: 16).copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _medal(BuildContext context) {
    final city = CityTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final photo = place?.medal;

    final Widget picture = photo == null
        ? RankSeal(level: rank.level, size: AppSizes.medal - AppSpacing.sm)
        : ClipOval(
            child: Image(
              image: photo,
              width: AppSizes.medal - AppSpacing.sm,
              height: AppSizes.medal - AppSpacing.sm,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => RankSeal(level: rank.level, size: AppSizes.medal - AppSpacing.sm),
            ),
          );

    return Container(
      width: AppSizes.medal,
      height: AppSizes.medal,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerLow,
        border: Border.all(
          color: _earned ? city.accent : scheme.outlineVariant,
          width: _earned ? 3 : 2,
        ),
      ),
      // A rank not reached yet is grey and faded; the tag and the order say it too.
      child: _earned
          ? picture
          : Opacity(opacity: 0.6, child: ColorFiltered(colorFilter: _greyscale, child: picture)),
    );
  }

  static const ColorFilter _greyscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}

/// Dotted path through the centers of the medals.
class _PathPainter extends CustomPainter {
  final Color color;
  final bool above;
  final bool below;

  const _PathPainter({required this.color, required this.above, required this.below});

  @override
  void paint(Canvas canvas, Size size) {
    const x = AppSizes.medal / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = AppSizes.trailDot
      ..strokeCap = StrokeCap.round;
    final from = above ? 0.0 : size.height / 2;
    final to = below ? size.height : size.height / 2;
    for (var y = from + AppSizes.trailDot; y < to; y += AppSizes.trailDot * 2.5) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 0.1), paint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.above != above || oldDelegate.below != below;
}

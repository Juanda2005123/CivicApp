import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/city_theme.dart';
import '../../../../core/widgets/city/city_photo_card.dart';
import '../../domain/entities/city.dart';

/// The city step of the registration: a photo card for each city with its own
/// pack that is in the coverage catalog. The one the GPS detected goes first.
/// The rest of the cities stay in the searchable list under these cards.
class FeaturedCityCards extends StatelessWidget {
  /// Coverage cities (RN-12), as the registration loaded them.
  final List<City> cities;
  final int? selectedCityId;

  /// The city the GPS found, or null.
  final int? detectedCityId;

  /// Null while the form is being sent.
  final ValueChanged<int>? onSelected;

  const FeaturedCityCards({
    super.key,
    required this.cities,
    required this.selectedCityId,
    required this.detectedCityId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cityTheme = CityTheme.of(context);

    final cards = <(City, CityShowcase)>[];
    for (final city in cities) {
      final showcase = cityTheme.showcaseFor(city.name, department: city.department);
      if (showcase != null) cards.add((city, showcase));
    }
    if (cards.isEmpty) return const SizedBox.shrink();

    // The showcase order, with the detected city on top.
    final order = cityTheme.showcase;
    cards.sort((a, b) {
      if (a.$1.id == detectedCityId) return -1;
      if (b.$1.id == detectedCityId) return 1;
      return order.indexOf(a.$2).compareTo(order.indexOf(b.$2));
    });
    final select = onSelected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('¿Dónde vas a cuidar la calle?', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final (city, showcase) in cards) ...[
          CityPhotoCard(
            key: ValueKey('city-card-${city.id}'),
            city: showcase,
            selected: city.id == selectedCityId,
            tag: city.id == detectedCityId ? 'Detectada por GPS' : null,
            onTap: select == null ? null : () => select(city.id),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text(
          '¿Otra ciudad? Búscala en la lista.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.field),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/dotted_spinner.dart';
import '../../../auth/domain/entities/city.dart';
import '../bloc/city_switcher_bloc.dart';
import '../bloc/city_switcher_event.dart';
import '../bloc/city_switcher_state.dart';

/// Opens the city switcher (HU-21) and answers the city the citizen picked, or
/// null if they closed it. The [CitySwitcherBloc] comes from the caller's tree.
Future<City?> showCitySwitcherSheet(BuildContext context, {required City current}) {
  final bloc = context.read<CitySwitcherBloc>();
  return showModalBottomSheet<City>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: CitySwitcherSheet(current: current),
    ),
  );
}

/// Bottom sheet to change the city of the map: recent cities and shortcuts
/// first, tolerant search as the citizen types. Stateful only to own the
/// search controller.
class CitySwitcherSheet extends StatefulWidget {
  final City current;

  const CitySwitcherSheet({super.key, required this.current});

  @override
  State<CitySwitcherSheet> createState() => _CitySwitcherSheetState();
}

class _CitySwitcherSheetState extends State<CitySwitcherSheet> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CitySwitcherBloc>().add(CitySwitcherOpened());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The sheet rises with the keyboard so the results stay visible.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.lg,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cambiar ciudad', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Estás viendo ${widget.current.displayName}.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Buscar ciudad o departamento',
              controller: _searchController,
              hint: 'Ej. Bogotá, Nariño',
              prefixIcon: LucideIcons.search,
              textInputAction: TextInputAction.search,
              onChanged: (value) => context.read<CitySwitcherBloc>().add(CityQueryChanged(value)),
            ),
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<CitySwitcherBloc, CitySwitcherState>(
              builder: (context, state) => _Body(state: state, current: widget.current),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final CitySwitcherState state;
  final City current;

  const _Body({required this.state, required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = state.options;

    if (state.status == CitySwitcherStatus.failure && options == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNotice(
            kind: NoticeKind.error,
            message: state.errorMessage ?? 'No pudimos cargar las ciudades.',
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: () => context.read<CitySwitcherBloc>().add(CitySwitcherOpened()),
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (options == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: DottedSpinner(size: 32, semanticLabel: 'Cargando ciudades')),
      );
    }

    if (state.isSearching) {
      if (state.results.isEmpty) {
        return const AppNotice(
          kind: NoticeKind.info,
          message: 'No encontramos esa ciudad. Revisa cómo la escribiste.',
        );
      }
      return _CityList(cities: state.results, current: current);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (options.recent.isNotEmpty) ...[
          Text('Recientes', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          _CityList(cities: options.recent, current: current),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text('Ciudades principales', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final city in options.quick)
              ActionChip(
                label: Text(city.name),
                avatar: city == current ? const Icon(LucideIcons.check, size: AppSizes.icon) : null,
                onPressed: () => Navigator.of(context).pop(city),
              ),
          ],
        ),
      ],
    );
  }
}

class _CityList extends StatelessWidget {
  final List<City> cities;
  final City current;

  const _CityList({required this.cities, required this.current});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final city in cities)
          ListTile(
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: AppSpacing.sm,
            leading: const Icon(LucideIcons.building2),
            title: Text('${city.name}, ${city.department}'),
            trailing: city == current
                ? const Icon(LucideIcons.check, semanticLabel: 'Ciudad actual')
                : null,
            onTap: () => Navigator.of(context).pop(city),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/dotted_spinner.dart';
import '../../../auth/domain/entities/coordinates.dart';
import '../../../reports/domain/entities/feed_incident.dart';
import '../../domain/entities/feed_filter_options.dart';
import '../../domain/entities/report_sort.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import '../widgets/choice_sheet.dart';
import '../widgets/feed_filter_bar.dart';
import '../widgets/feed_incident_card.dart';
import 'package:vigia_app/core/widgets/city/city_motion.dart';

/// "Comunidad" tab of the shell (HU-19): the reports of the active city, newest
/// first, 20 at a time as the citizen scrolls, with pull-to-refresh. A Page, so
/// it has no Scaffold of its own. Stateful only to own the [ScrollController].
///
/// Above the list, the search bar and the filters (HU-20): the text, the
/// category, the neighborhood and the order are kept by the [FeedBloc], which
/// the map reads too. With no match, the empty state offers "Limpiar filtros".
///
/// The city arrives through the [FeedBloc] (the shell forwards it from the
/// map); [myLocation] only adds the distance to each card.
class FeedPage extends StatefulWidget {
  /// The citizen's position, or null when it is unknown: cards hide the distance.
  final Coordinates? myLocation;

  /// Called by the empty state: the shell decides whether to open the wizard or
  /// the sign-in modal for a guest (HU-22).
  final VoidCallback onReportPressed;

  /// Asked when the citizen orders by "Más cercanos" and the position is not
  /// known: the shell tries to locate them and answers whether it could. If not,
  /// the previous order stays (HU-20, criterion 4).
  final Future<bool> Function()? onLocationNeeded;

  /// A report changed in its detail (edited or deleted, HU-18): the shell reloads.
  final VoidCallback? onReportChanged;

  const FeedPage({
    super.key,
    this.myLocation,
    required this.onReportPressed,
    this.onLocationNeeded,
    this.onReportChanged,
  });

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  /// The next page is asked when this little is left to scroll.
  static const double _loadMoreDistance = 600;

  /// Room under the last card so the "Reportar daño" button does not cover it.
  static const double _bottomClearance = AppSpacing.xxxl + AppSizes.button + AppSpacing.lg;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Asks for the next page near the end of the list. After a failed page the
  /// citizen has to tap "Reintentar": scrolling must not ask again and again.
  void _onScroll() {
    final bloc = context.read<FeedBloc>();
    final state = bloc.state;
    if (!_scrollController.hasClients ||
        !state.hasMore ||
        state.isLoadingMore ||
        state.loadMoreFailed ||
        state.status != FeedStatus.success) {
      return;
    }
    if (_scrollController.position.extentAfter < _loadMoreDistance) {
      bloc.add(FeedNextPageRequested());
    }
  }

  /// Completes when the reload ends, so the indicator spins for as long as it
  /// takes. A refresh that is already running (or a page loading) is not repeated.
  Future<void> _refresh() async {
    final bloc = context.read<FeedBloc>();
    if (bloc.state.status == FeedStatus.loading || bloc.state.isLoadingMore) return;

    final done = bloc.stream.firstWhere((state) => state.status != FeedStatus.loading);
    bloc.add(FeedRefreshed());
    await done;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedBloc, FeedState>(
      builder: (context, state) {
        final city = state.city;

        // The map has not resolved the city yet, or the first page is on its way.
        if (city == null || (state.status == FeedStatus.loading && state.items.isEmpty)) {
          return const Center(child: DottedSpinner(size: 40, semanticLabel: 'Cargando los reportes'));
        }

        final filter = state.filter;
        final visible = filter.applyToFeed(state.items, myLocation: widget.myLocation);

        final Widget body;
        if (state.items.isEmpty) {
          body = state.status == FeedStatus.failure
              ? _Message(
                  icon: LucideIcons.cloudOff,
                  title: 'No pudimos cargar los reportes',
                  message: state.errorMessage ?? 'Revisa tu conexión e inténtalo de nuevo.',
                  actionLabel: 'Reintentar',
                  onAction: () => context.read<FeedBloc>().add(FeedRefreshed()),
                )
              : _Message(
                  icon: LucideIcons.mapPinPlus,
                  title: 'Aún no hay reportes en ${city.name}',
                  message: 'Sé la primera persona en reportar un daño en tu ciudad.',
                  actionLabel: 'Reportar daño',
                  onAction: widget.onReportPressed,
                );
        } else if (visible.isEmpty && state.isLoadingMore) {
          // The rest of the city is still arriving: it may hold a match.
          body = const Center(child: DottedSpinner(size: 32, semanticLabel: 'Buscando en los reportes'));
        } else if (visible.isEmpty && state.loadMoreFailed) {
          body = _Message(
            icon: LucideIcons.cloudOff,
            title: 'No pudimos buscar en todos los reportes',
            message: state.errorMessage ?? 'Revisa tu conexión e inténtalo de nuevo.',
            actionLabel: 'Reintentar',
            onAction: () => context.read<FeedBloc>().add(FeedAllPagesRequested()),
          );
        } else if (visible.isEmpty) {
          body = _Message(
            icon: LucideIcons.searchX,
            title: 'Ningún reporte coincide',
            message: 'Prueba con otras palabras o quita algún filtro para ver los reportes de ${city.name}.',
            actionLabel: 'Limpiar filtros',
            onAction: () => context.read<FeedBloc>().add(FeedFiltersCleared()),
          );
        } else {
          body = _buildList(context, state, visible);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CityHeader(cityName: '${city.name}, ${city.department}'),
            // A city with no reports at all has nothing to search.
            if (state.items.isNotEmpty)
              FeedFilterBar(
                filter: filter,
                resultCount: filter.isActive ? visible.length : null,
                onQueryChanged: (query) => context.read<FeedBloc>().add(FeedSearchChanged(query)),
                onCategoryPressed: _openCategorySheet,
                onNeighborhoodPressed: _openNeighborhoodSheet,
                onSortPressed: _openSortSheet,
                onClearFilters: () => context.read<FeedBloc>().add(FeedFiltersCleared()),
              ),
            Expanded(child: RefreshIndicator(onRefresh: _refresh, child: body)),
          ],
        );
      },
    );
  }

  /// Opens the report detail. It answers `true` when the author edited or deleted
  /// the report there (HU-18), and then the shell reloads the map and the feed.
  Future<void> _openReport(String incidentId) async {
    final changed = await Navigator.pushNamed(context, AppRoutes.reportDetail, arguments: incidentId);
    if (changed == true && mounted) widget.onReportChanged?.call();
  }

  /// The sheets list what the city has, which may still be loading when they
  /// open: they ask for the rest of the pages and redraw as they arrive.
  void _openCategorySheet() {
    final bloc = context.read<FeedBloc>()..add(FeedAllPagesRequested());
    showChoiceSheet<String?>(
      context,
      title: 'Categoría',
      updates: bloc.stream,
      selected: () => bloc.state.filter.categoryName,
      options: () => [
        const ChoiceOption<String?>('Todas las categorías', null),
        for (final name in FeedFilterOptions.fromItems(bloc.state.items).categories) ChoiceOption<String?>(name, name),
      ],
      onSelected: (name) => bloc.add(FeedCategorySelected(name)),
    );
  }

  void _openNeighborhoodSheet() {
    final bloc = context.read<FeedBloc>()..add(FeedAllPagesRequested());
    showChoiceSheet<String?>(
      context,
      title: 'Barrio',
      updates: bloc.stream,
      selected: () => bloc.state.filter.neighborhood,
      options: () => [
        const ChoiceOption<String?>('Todos los barrios', null),
        for (final name in FeedFilterOptions.fromItems(bloc.state.items).neighborhoods)
          ChoiceOption<String?>(name, name),
      ],
      onSelected: (name) => bloc.add(FeedNeighborhoodSelected(name)),
    );
  }

  void _openSortSheet() {
    final bloc = context.read<FeedBloc>();
    showChoiceSheet<ReportSort>(
      context,
      title: 'Ordenar por',
      selected: () => bloc.state.filter.sort,
      options: () => [for (final sort in ReportSort.values) ChoiceOption<ReportSort>(sort.labelSpanish, sort)],
      onSelected: _selectSort,
    );
  }

  /// "Más cercanos" needs the position. When it cannot be found the previous
  /// order stays and the citizen is told how to turn the location on.
  Future<void> _selectSort(ReportSort sort) async {
    final bloc = context.read<FeedBloc>();
    if (sort == ReportSort.nearest && widget.myLocation == null) {
      final located = await (widget.onLocationNeeded?.call() ?? Future.value(false));
      if (!mounted) return;
      if (!located) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text('Para ordenar por cercanía activa tu ubicación. Dejamos el orden anterior.'),
          ));
        return;
      }
    }
    bloc.add(FeedSortSelected(sort));
  }

  Widget _buildList(BuildContext context, FeedState state, List<FeedIncident> visible) {
    final failedRefresh = state.status == FeedStatus.failure;
    final hasFooter = state.isLoadingMore || state.loadMoreFailed;
    final location = widget.myLocation;

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, _bottomClearance),
      // A failed refresh keeps the list and puts the notice on top (criterion 5).
      itemCount: (failedRefresh ? 1 : 0) + visible.length + (hasFooter ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (failedRefresh) {
          if (index == 0) {
            return _RetryNotice(
              message: state.errorMessage ?? 'No pudimos actualizar los reportes.',
              onRetry: () => context.read<FeedBloc>().add(FeedRefreshed()),
            );
          }
          index -= 1;
        }

        if (index == visible.length) {
          return state.loadMoreFailed
              ? _RetryNotice(
                  message: state.errorMessage ?? 'No pudimos cargar más reportes.',
                  onRetry: () => context.read<FeedBloc>().add(FeedNextPageRequested()),
                )
              : const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: DottedSpinner(size: 32, semanticLabel: 'Cargando más reportes')),
                );
        }

        final incident = visible[index];
        return FeedIncidentCard(
          incident: incident,
          distanceMeters: location == null ? null : incident.coordinates.distanceInMetersTo(location),
          onTap: () => _openReport(incident.id),
        );
      },
    );
  }
}

/// The active city, so the citizen knows whose reports they are reading.
class _CityHeader extends StatelessWidget {
  final String cityName;

  const _CityHeader({required this.cityName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        children: [
          Icon(LucideIcons.building2, size: AppSizes.icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(cityName, style: theme.textTheme.titleSmall)),
        ],
      ),
    );
  }
}

/// A message that fills the page (empty city, failed first load). It scrolls, so
/// pull-to-refresh still works on it.
class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: AppSpacing.xxxl, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: AppSpacing.lg),
                  Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PressScale(child: OutlinedButton(onPressed: onAction, child: Text(actionLabel))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An error that leaves the list on screen, with its own "Reintentar".
class _RetryNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _RetryNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNotice(kind: NoticeKind.error, message: message),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/dotted_spinner.dart';
import '../../../auth/domain/entities/coordinates.dart';
import '../bloc/feed_bloc.dart';
import '../bloc/feed_event.dart';
import '../bloc/feed_state.dart';
import '../widgets/feed_incident_card.dart';

/// "Comunidad" tab of the shell (HU-19): the reports of the active city, newest
/// first, 20 at a time as the citizen scrolls, with pull-to-refresh. A Page, so
/// it has no Scaffold of its own. Stateful only to own the [ScrollController].
///
/// The city arrives through the [FeedBloc] (the shell forwards it from the
/// map); [myLocation] only adds the distance to each card.
class FeedPage extends StatefulWidget {
  /// The citizen's position, or null when it is unknown: cards hide the distance.
  final Coordinates? myLocation;

  /// Called by the empty state: the shell decides whether to open the wizard or
  /// the sign-in modal for a guest (HU-22).
  final VoidCallback onReportPressed;

  /// A report changed in its detail (edited or deleted, HU-18): the shell reloads.
  final VoidCallback? onReportChanged;

  const FeedPage({super.key, this.myLocation, required this.onReportPressed, this.onReportChanged});

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

        final Widget body;
        if (state.items.isEmpty) {
          body = state.status == FeedStatus.failure
              ? _Message(
                  icon: Icons.cloud_off_outlined,
                  title: 'No pudimos cargar los reportes',
                  message: state.errorMessage ?? 'Revisa tu conexión e inténtalo de nuevo.',
                  actionLabel: 'Reintentar',
                  onAction: () => context.read<FeedBloc>().add(FeedRefreshed()),
                )
              : _Message(
                  icon: Icons.add_location_alt_outlined,
                  title: 'Aún no hay reportes en ${city.name}',
                  message: 'Sé la primera persona en reportar un daño en tu ciudad.',
                  actionLabel: 'Reportar daño',
                  onAction: widget.onReportPressed,
                );
        } else {
          body = _buildList(context, state);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CityHeader(cityName: '${city.name}, ${city.department}'),
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

  Widget _buildList(BuildContext context, FeedState state) {
    final failedRefresh = state.status == FeedStatus.failure;
    final hasFooter = state.isLoadingMore || state.loadMoreFailed;
    final location = widget.myLocation;

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, _bottomClearance),
      // A failed refresh keeps the list and puts the notice on top (criterion 5).
      itemCount: (failedRefresh ? 1 : 0) + state.items.length + (hasFooter ? 1 : 0),
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

        if (index == state.items.length) {
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

        final incident = state.items[index];
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
          Icon(Icons.location_city_outlined, size: AppSizes.icon, color: theme.colorScheme.onSurfaceVariant),
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
                  OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
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

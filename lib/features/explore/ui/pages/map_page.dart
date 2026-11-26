import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/dotted_spinner.dart';
import '../../../../core/widgets/location_blocked_dialog.dart';
import '../../../auth/domain/entities/city.dart';
import '../../../reports/domain/entities/incident_marker.dart';
import '../../domain/entities/report_filter.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../widgets/city_switcher_sheet.dart';
import '../widgets/incident_map_marker.dart';

/// "Mapa" tab of the shell (HU-13): the reports of the citizen's city as
/// markers, and a button to center the map on the citizen's position. A Page,
/// so it has no Scaffold of its own. Stateful only to own the [MapController].
class MapPage extends StatefulWidget {
  /// A report changed in its detail (edited or deleted, HU-18): the shell reloads.
  final VoidCallback? onReportChanged;

  /// The search and filters of Comunidad also narrow the pins (HU-20, criterion 5).
  final ReportFilter filter;

  /// "Limpiar filtros" of the notice shown while a filter hides some pins.
  final VoidCallback? onClearFilters;

  const MapPage({
    super.key,
    this.onReportChanged,
    this.filter = const ReportFilter(),
    this.onClearFilters,
  });

  /// Street level that still shows several neighborhoods.
  static const double initialZoom = 13;

  /// Closer zoom when centering on the citizen: the street and its corners.
  /// OpenStreetMap tiles go up to 19.
  static const double myLocationZoom = 18;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  /// OpenStreetMap tiles need no API key. CARTO basemaps now answer every tile
  /// with an "API KEY REQUIRED" image, so they are not used. In the dark theme
  /// the same tiles are darkened with flutter_map's `darkModeTileBuilder`.
  static const String _tiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  final _mapController = MapController();

  // The camera cannot move before the map's first frame: a position that
  // arrives earlier waits here and is applied in `onMapReady`.
  bool _mapReady = false;
  LatLng? _pendingCenter;

  void _centerOn(LatLng point) {
    if (_mapReady) {
      _mapController.move(point, MapPage.myLocationZoom);
    } else {
      _pendingCenter = point;
    }
  }

  /// A city chosen on the switcher (HU-21) takes the camera to its centre: the
  /// button and the markers change, so the view must follow them.
  void _showCity(City city) {
    if (!_mapReady) return;
    _mapController.move(LatLng(city.latitude, city.longitude), MapPage.initialZoom);
  }

  void _onMapReady() {
    _mapReady = true;
    final pending = _pendingCenter;
    if (pending == null) return;
    _pendingCenter = null;
    _mapController.move(pending, MapPage.myLocationZoom);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Moving the camera and opening the modal are side effects, so they run
    // once per state in the listener, never in the builder.
    return BlocListener<MapBloc, MapState>(
      // Only a change of city after the first load: the first one opens on the
      // citizen's position or on the city through `initialCenter`.
      listenWhen: (previous, current) => previous.city != null && current.city != null && previous.city != current.city,
      listener: (context, state) => _showCity(state.city!),
      child: BlocConsumer<MapBloc, MapState>(
        listenWhen: (previous, current) => previous.myLocationStatus != current.myLocationStatus,
        listener: (context, state) {
          switch (state.myLocationStatus) {
            case MyLocationStatus.found:
              final position = state.myLocation;
              if (position == null) return;
              _centerOn(LatLng(position.latitude, position.longitude));
            case MyLocationStatus.blocked:
              final message = state.myLocationMessage;
              if (message == null) return;
              final bloc = context.read<MapBloc>();
              showLocationBlockedDialog(
                context,
                message: message,
                onOpenSettings: () => bloc.add(LocationSettingsRequested()),
              );
            default:
              break;
          }
        },
        builder: (context, state) {
          final city = state.city;

          if (state.status == MapStatus.failure && city == null) {
            return _LoadError(
              message: state.errorMessage ?? 'No pudimos cargar el mapa.',
              onRetry: () => context.read<MapBloc>().add(MapStarted()),
            );
          }

          if (city == null) {
            return const Center(child: DottedSpinner(size: 40, semanticLabel: 'Cargando el mapa'));
          }

          final myLocation = state.myLocation;
          final shownMarkers = widget.filter.applyToMarkers(state.markers);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                // A position known before the first frame becomes the starting
                // view; one that arrives later moves the camera in the listener.
                options: MapOptions(
                  initialCenter: myLocation != null
                      ? LatLng(myLocation.latitude, myLocation.longitude)
                      : LatLng(city.latitude, city.longitude),
                  initialZoom: myLocation != null ? MapPage.myLocationZoom : MapPage.initialZoom,
                  onMapReady: _onMapReady,
                ),
                children: [
                  TileLayer(
                    urlTemplate: _tiles,
                    userAgentPackageName: 'com.vigia.vigia_app',
                    tileBuilder: isDark ? darkModeTileBuilder : null,
                  ),
                  MarkerLayer(
                    markers: [
                      for (final marker in shownMarkers) _toMapMarker(context, marker),
                      if (myLocation != null)
                        Marker(
                          point: LatLng(myLocation.latitude, myLocation.longitude),
                          width: _MyLocationDot.size,
                          height: _MyLocationDot.size,
                          child: const _MyLocationDot(),
                        ),
                    ],
                  ),
                  const SimpleAttributionWidget(source: Text('© OpenStreetMap')),
                ],
              ),
              // Notices on the left, the button on the right, so they never overlap.
              Positioned(
                top: AppSpacing.lg,
                left: AppSpacing.lg,
                right: AppSpacing.lg + AppSizes.touchTarget + AppSpacing.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CityButton(
                      city: city,
                      isLoading: state.status == MapStatus.loading,
                      onPressed: () => _switchCity(context, city),
                    ),
                    // Some pins are hidden by the filters of Comunidad: say so, with a way out.
                    if (widget.filter.isActive) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _ActiveFiltersNotice(
                        filterCount: widget.filter.activeCount,
                        shown: shownMarkers.length,
                        total: state.markers.length,
                        onClear: widget.onClearFilters,
                      ),
                    ],
                    // The city could not be saved or loaded: the map keeps the previous one.
                    if (state.status == MapStatus.failure && state.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppNotice(kind: NoticeKind.error, message: state.errorMessage!),
                    ],
                    // A blocked permission is explained in the modal instead.
                    if (state.myLocationMessage != null && state.myLocationStatus != MyLocationStatus.blocked) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppNotice(kind: NoticeKind.error, message: state.myLocationMessage!),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: AppSpacing.lg,
                right: AppSpacing.lg,
                child: _MyLocationButton(
                  isLocating: state.myLocationStatus == MyLocationStatus.locating,
                  onPressed: () => context.read<MapBloc>().add(MyLocationRequested()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _switchCity(BuildContext context, City current) async {
    final bloc = context.read<MapBloc>();
    final picked = await showCitySwitcherSheet(context, current: current);
    if (picked == null || picked == current) return;
    bloc.add(CitySelected(picked));
  }

  /// Opens the report detail. It answers `true` when the author edited or deleted
  /// the report there (HU-18), and then the shell reloads the map and the feed.
  Future<void> _openReport(String incidentId) async {
    final changed = await Navigator.pushNamed(context, AppRoutes.reportDetail, arguments: incidentId);
    if (changed == true && mounted) widget.onReportChanged?.call();
  }

  Marker _toMapMarker(BuildContext context, IncidentMarker marker) {
    return Marker(
      point: LatLng(marker.coordinates.latitude, marker.coordinates.longitude),
      width: AppSizes.touchTarget,
      height: AppSizes.touchTarget,
      child: IncidentMapMarker(
        severity: marker.severity,
        categoryIcon: marker.categoryIcon,
        semanticLabel: '${marker.title}, ${marker.categoryName}, gravedad ${marker.severity.labelSpanish}',
        onTap: () => _openReport(marker.id),
      ),
    );
  }
}

/// Shows the city on the map and opens the switcher (HU-21): a solid surface
/// with a 1 px border, like the other overlays, so it reads on any tile.
class _CityButton extends StatelessWidget {
  final City city;
  final bool isLoading;
  final VoidCallback onPressed;

  const _CityButton({required this.city, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.touchTarget),
          backgroundColor: scheme.surface,
          disabledBackgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        icon: isLoading
            ? const DottedSpinner(size: AppSizes.icon, semanticLabel: 'Cargando la ciudad')
            : const Icon(LucideIcons.building2, size: AppSizes.icon),
        label: Text('${city.name}, ${city.department}', overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Round 48 dp button over the map: a solid surface with a 1 px border, as
/// the design system asks for overlays (no glass).
class _MyLocationButton extends StatelessWidget {
  final bool isLocating;
  final VoidCallback onPressed;

  const _MyLocationButton({required this.isLocating, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: 'Centrar en mi ubicación',
      onPressed: isLocating ? null : onPressed,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(AppSizes.touchTarget),
        backgroundColor: scheme.surface,
        disabledBackgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      icon: isLocating
          ? const DottedSpinner(size: AppSizes.icon, semanticLabel: 'Buscando tu ubicación')
          : const Icon(LucideIcons.locateFixed),
    );
  }
}

/// Where the citizen is: a filled dot with a surface ring, so it reads on both
/// light and darkened tiles and never looks like a report marker.
class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  static const double size = AppSpacing.lg + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // container: its own node, or the label merges with the map's attribution.
    return Semantics(
      container: true,
      label: 'Tu ubicación',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.semantic.info,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.surface, width: AppSpacing.xs - 1),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.map, size: AppSpacing.xxxl, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.lg),
            Text('No pudimos cargar el mapa', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// While the filters of Comunidad are on: how many pins they leave and a
/// one-tap way to clear them (HU-20, criterion 5). Solid surface with a 1 px
/// border like the other overlays, so it reads on any tile.
class _ActiveFiltersNotice extends StatelessWidget {
  final int filterCount;
  final int shown;
  final int total;
  final VoidCallback? onClear;

  const _ActiveFiltersNotice({
    required this.filterCount,
    required this.shown,
    required this.total,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = filterCount == 1 ? '1 filtro activo' : '$filterCount filtros activos';

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.small,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: Row(
          children: [
            Icon(LucideIcons.slidersHorizontal, size: AppSizes.icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '$label: $shown de $total reportes',
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (onClear != null) TextButton(onPressed: onClear, child: const Text('Limpiar')),
          ],
        ),
      ),
    );
  }
}

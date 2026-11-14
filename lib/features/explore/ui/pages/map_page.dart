import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/dotted_spinner.dart';
import '../../../reports/domain/entities/incident_marker.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../widgets/incident_map_marker.dart';

/// "Mapa" tab of the shell (HU-13): the reports of the citizen's city as
/// markers, and a button to center the map on the citizen's position. A Page,
/// so it has no Scaffold of its own. Stateful only to own the [MapController].
class MapPage extends StatefulWidget {
  const MapPage({super.key});

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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Moving the camera is a side effect, so it runs once per state in the
    // listener, never in the builder.
    return BlocConsumer<MapBloc, MapState>(
      listenWhen: (previous, current) =>
          previous.myLocationStatus != current.myLocationStatus &&
          current.myLocationStatus == MyLocationStatus.found,
      listener: (context, state) {
        final position = state.myLocation;
        if (position == null) return;
        _mapController.move(LatLng(position.latitude, position.longitude), MapPage.myLocationZoom);
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

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(city.latitude, city.longitude),
                initialZoom: MapPage.initialZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: _tiles,
                  userAgentPackageName: 'com.vigia.vigia_app',
                  tileBuilder: isDark ? darkModeTileBuilder : null,
                ),
                MarkerLayer(
                  markers: [
                    for (final marker in state.markers) _toMapMarker(context, marker),
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
                  if (state.myLocationMessage != null)
                    AppNotice(kind: NoticeKind.error, message: state.myLocationMessage!),
                  if (state.myLocationStatus == MyLocationStatus.blocked) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: () => context.read<MapBloc>().add(LocationSettingsRequested()),
                        icon: const Icon(Icons.settings_outlined, size: AppSizes.icon),
                        label: const Text('Abrir ajustes'),
                      ),
                    ),
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
    );
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
        onTap: () => Navigator.pushNamed(context, AppRoutes.reportDetail, arguments: marker.id),
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
          : const Icon(Icons.my_location),
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
            Icon(Icons.map_outlined, size: AppSpacing.xxxl, color: theme.colorScheme.error),
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

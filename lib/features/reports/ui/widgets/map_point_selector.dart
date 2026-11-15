import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_text_styles.dart';
import 'package:vigia_app/core/widgets/dotted_spinner.dart';
import 'package:vigia_app/core/widgets/primary_button.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

/// Step 1 map (HU-27): the citizen pans the map under a fixed center pin and
/// confirms the point. Stateful only to own the [MapController] and the
/// center being shown.
class MapPointSelector extends StatefulWidget {
  /// Where the map opens; when it changes (a GPS reading), the map follows.
  final Coordinates coordinates;
  final bool isLocating;
  final VoidCallback? onUseMyLocation;
  final ValueChanged<Coordinates> onConfirmed;
  final VoidCallback onCancel;

  /// Height the step has on screen; with enough of it, the map grows to fill
  /// it instead of leaving empty space below the buttons.
  final double? availableHeight;

  const MapPointSelector({
    super.key,
    required this.coordinates,
    this.isLocating = false,
    this.onUseMyLocation,
    required this.onConfirmed,
    required this.onCancel,
    this.availableHeight,
  });

  /// Street level with its corners; OpenStreetMap tiles go up to 19.
  static const double zoom = 17;

  @override
  State<MapPointSelector> createState() => _MapPointSelectorState();
}

class _MapPointSelectorState extends State<MapPointSelector> {
  /// Same tiles as the "Mapa" tab: OpenStreetMap needs no API key.
  static const String _tiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  final _mapController = MapController();
  bool _mapReady = false;
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _center = _toLatLng(widget.coordinates);
  }

  @override
  void didUpdateWidget(covariant MapPointSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coordinates != oldWidget.coordinates) {
      final point = _toLatLng(widget.coordinates);
      setState(() => _center = point);
      if (_mapReady) _mapController.move(point, MapPointSelector.zoom);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  static LatLng _toLatLng(Coordinates c) => LatLng(c.latitude, c.longitude);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final available = widget.availableHeight;
    // Fill the step when there is room; on short screens (landscape) the map
    // keeps its fixed height and the step scrolls.
    final fill = available != null && available >= AppSizes.mapPicker * 2;

    final map = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: SizedBox(
          height: fill ? null : AppSizes.mapPicker,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: MapPointSelector.zoom,
                  onMapReady: () => _mapReady = true,
                  onPositionChanged: (camera, _) => setState(() => _center = camera.center),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _tiles,
                    userAgentPackageName: 'com.vigia.vigia_app',
                    tileBuilder: isDark ? darkModeTileBuilder : null,
                  ),
                  const SimpleAttributionWidget(source: Text('OpenStreetMap')),
                ],
              ),
              // The pin's tip sits on the map center: the padding lifts
              // the icon by its own height.
              IgnorePointer(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.mapPin),
                    child: Semantics(
                      label: 'Punto del daño',
                      child: Icon(Icons.location_on, size: AppSizes.mapPin, color: scheme.primary),
                    ),
                  ),
                ),
              ),
              if (widget.onUseMyLocation != null)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: IconButton(
                    tooltip: 'Centrar en mi ubicación',
                    onPressed: widget.isLocating ? null : widget.onUseMyLocation,
                    style: IconButton.styleFrom(
                      fixedSize: const Size.square(AppSizes.touchTarget),
                      backgroundColor: scheme.surface,
                      disabledBackgroundColor: scheme.surface,
                      foregroundColor: scheme.onSurface,
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    icon: widget.isLocating
                        ? const DottedSpinner(size: AppSizes.icon, semanticLabel: 'Buscando tu ubicación')
                        : const Icon(Icons.my_location),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Selecciona el punto en el mapa',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Mueve el mapa hasta que el pin quede sobre el daño.',
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        if (fill) Expanded(child: map) else map,
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_center.latitude.toStringAsFixed(5)}°, ${_center.longitude.toStringAsFixed(5)}°',
          textAlign: TextAlign.center,
          style: AppTextStyles.data(size: 13).copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'Confirmar punto',
          onPressed: () => widget.onConfirmed(Coordinates(latitude: _center.latitude, longitude: _center.longitude)),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton(onPressed: widget.onCancel, child: const Text('Volver')),
      ],
    );
    return fill ? SizedBox(height: available, child: content) : content;
  }
}

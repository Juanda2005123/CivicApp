import 'package:flutter/material.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_text_styles.dart';
import 'package:vigia_app/core/widgets/app_notice.dart';
import 'package:vigia_app/core/widgets/app_text_field.dart';
import 'package:vigia_app/core/widgets/dotted_spinner.dart';
import 'package:vigia_app/core/widgets/primary_button.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import 'package:vigia_app/features/reports/domain/entities/address_outcome.dart';
import 'package:vigia_app/features/reports/domain/entities/location_source.dart';
import 'package:vigia_app/features/reports/domain/entities/suggested_address.dart';
import 'package:vigia_app/features/reports/domain/validators/report_validators.dart';
import 'map_point_selector.dart';

/// Step 1: Location georeferencing and Colombian address confirmation (HU-07).
class LocationPinPicker extends StatefulWidget {
  final Coordinates? initialCoordinates;
  final String? initialAddress;
  final String? initialNeighborhood;
  final String? initialCity;
  final bool isLocating;
  final String? locationStatusMessage;

  /// Address suggested from the GPS (HU-26): it overwrites the fields it has
  /// data for, and every field stays editable.
  final SuggestedAddress? suggestedAddress;

  /// The suggestion is still arriving: the main road field shows the loading
  /// ring until the address comes, and the cross street field until the end.
  final bool isSuggestingAddress;

  /// Why the suggestion is missing or incomplete; shown as a notice.
  final String? suggestionMessage;

  /// Reads the device GPS; offered on the map as "Centrar en mi ubicación".
  final VoidCallback? onDetectLocation;

  /// The citizen confirmed a point on the map (HU-27).
  final ValueChanged<Coordinates>? onMapPointSelected;

  /// Height the step has on screen, so the map can fill it.
  final double? availableHeight;

  /// Where the point comes from (HU-28): the label under the coordinates tells
  /// an exact point (GPS, map) from an estimate (address, city center).
  final LocationSource coordinatesSource;

  /// The typed address is being searched: the confirm button shows it.
  final bool isGeocodingAddress;

  /// How the search of the typed address ended; explained in a notice with the
  /// next step to take. Null before any search.
  final AddressOutcome? addressOutcome;
  final void Function({
    required Coordinates coordinates,
    required String formattedAddress,
    required String neighborhood,
    required String city,
  }) onLocationConfirmed;

  const LocationPinPicker({
    super.key,
    this.initialCoordinates,
    this.initialAddress,
    this.initialNeighborhood,
    this.initialCity,
    this.isLocating = false,
    this.locationStatusMessage,
    this.suggestedAddress,
    this.isSuggestingAddress = false,
    this.suggestionMessage,
    this.onDetectLocation,
    this.onMapPointSelected,
    this.availableHeight,
    this.coordinatesSource = LocationSource.cityCenter,
    this.isGeocodingAddress = false,
    this.addressOutcome,
    required this.onLocationConfirmed,
  });

  @override
  State<LocationPinPicker> createState() => _LocationPinPickerState();
}

class _LocationPinPickerState extends State<LocationPinPicker> {
  final _formKey = GlobalKey<FormState>();

  // Free-form address / reference controller
  late final TextEditingController _freeAddressController;
  late final TextEditingController _neighborhoodController;

  // Structured nomenclature fields
  bool _useStructuredAddress = true;
  String _selectedRoadType = 'Carrera';
  late final TextEditingController _mainRoadNumberController;
  late final TextEditingController _crossRoadNumberController;
  late final TextEditingController _plaqueNumberController;

  late Coordinates _coordinates;
  late String _city;

  /// Shows the "review the suggestion" notice once a suggestion was applied.
  bool _suggestionApplied = false;

  /// What the form said when the last address search ended. The notice about
  /// the result only shows while the form still says the same: after an edit it
  /// would be about an address that is no longer there.
  String? _outcomeSignature;

  /// Step 1 shows the map instead of the address form (HU-27). The form stays
  /// in this State, so its fields keep what was typed.
  bool _pickingOnMap = false;

  static const List<String> _roadTypes = [
    'Carrera',
    'Calle',
    'Avenida',
    'Diagonal',
    'Transversal',
    'Circular',
    'Autopista',
  ];

  /// Roads that are known by a name, not only by a number ("Autopista Sur",
  /// "Avenida Roosevelt"): the main road of these types needs no digit.
  static const Set<String> _namedRoadTypes = {'Avenida', 'Autopista'};

  @override
  void initState() {
    super.initState();
    _coordinates = widget.initialCoordinates ??
        const Coordinates(latitude: 3.4516, longitude: -76.5320); // Default Cali
    _city = widget.initialCity ?? 'Cali';

    _freeAddressController =
        TextEditingController(text: widget.initialAddress ?? '');
    _neighborhoodController =
        TextEditingController(text: widget.initialNeighborhood ?? '');

    _mainRoadNumberController = TextEditingController();
    _crossRoadNumberController = TextEditingController();
    _plaqueNumberController = TextEditingController();

    _mainRoadNumberController.addListener(_onStructuredFieldChanged);
    _crossRoadNumberController.addListener(_onStructuredFieldChanged);
    _plaqueNumberController.addListener(_onStructuredFieldChanged);

    // If initial address contains structured tokens, populate or fall back to free mode
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _tryParseInitialAddress(widget.initialAddress!);
    } else {
      // The wizard suggests the address on opening (HU-26); it may already
      // be here when the step is first drawn.
      final suggestion = widget.suggestedAddress;
      if (suggestion != null) _fillFromSuggestion(suggestion, null);
    }

    // Back from Step 2 the picker is built again with the result already known.
    if (widget.addressOutcome != null) _outcomeSignature = _formSignature();
  }

  void _onStructuredFieldChanged() {
    setState(() {});
  }

  /// The address and neighborhood as typed, to tell if they changed.
  String _formSignature() => '${_buildFormattedAddress()}|${_neighborhoodController.text.trim()}';

  void _tryParseInitialAddress(String address) {
    // 1. Detection with plaque: "Tipo Vía # Cruce - Placa"
    final regexWithPlaque = RegExp(
      r'^(Carrera|Calle|Avenida|Diagonal|Transversal|Circular|Autopista)\s+([^#]+)#\s*([^-]+)-\s*(.+)$',
      caseSensitive: false,
    );
    final matchWithPlaque = regexWithPlaque.firstMatch(address.trim());
    if (matchWithPlaque != null) {
      final matchedType = _roadTypes.firstWhere(
        (t) => t.toLowerCase() == matchWithPlaque.group(1)!.toLowerCase(),
        orElse: () => 'Carrera',
      );
      _selectedRoadType = matchedType;
      _mainRoadNumberController.text = matchWithPlaque.group(2)!.trim();
      _crossRoadNumberController.text = matchWithPlaque.group(3)!.trim();
      _plaqueNumberController.text = matchWithPlaque.group(4)!.trim();
      _useStructuredAddress = true;
      return;
    }

    // 2. Detection without plaque: "Tipo Vía # Cruce"
    final regexNoPlaque = RegExp(
      r'^(Carrera|Calle|Avenida|Diagonal|Transversal|Circular|Autopista)\s+([^#]+)#\s*(.+)$',
      caseSensitive: false,
    );
    final matchNoPlaque = regexNoPlaque.firstMatch(address.trim());
    if (matchNoPlaque != null) {
      final matchedType = _roadTypes.firstWhere(
        (t) => t.toLowerCase() == matchNoPlaque.group(1)!.toLowerCase(),
        orElse: () => 'Carrera',
      );
      _selectedRoadType = matchedType;
      _mainRoadNumberController.text = matchNoPlaque.group(2)!.trim();
      _crossRoadNumberController.text = matchNoPlaque.group(3)!.trim();
      _plaqueNumberController.text = '';
      _useStructuredAddress = true;
      return;
    }

    _useStructuredAddress = false;
    _freeAddressController.text = address;
  }

  @override
  void didUpdateWidget(covariant LocationPinPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCoordinates != null &&
        widget.initialCoordinates != oldWidget.initialCoordinates) {
      setState(() {
        _coordinates = widget.initialCoordinates!;
      });
    }
    if (widget.initialCity != null && widget.initialCity != oldWidget.initialCity) {
      setState(() {
        _city = widget.initialCity!;
      });
    }
    final suggestion = widget.suggestedAddress;
    if (suggestion != null && suggestion != oldWidget.suggestedAddress) {
      setState(() => _fillFromSuggestion(suggestion, oldWidget.suggestedAddress));
    }
    if (widget.addressOutcome != oldWidget.addressOutcome) {
      _outcomeSignature = widget.addressOutcome == null ? null : _formSignature();
    }
  }

  /// Overwrites only the fields the suggestion has data for (HU-26). The
  /// cross street arrives later as an update of the [previous] suggestion;
  /// that update leaves alone the fields it does not change, which the
  /// citizen may already be correcting.
  void _fillFromSuggestion(SuggestedAddress suggestion, SuggestedAddress? previous) {
    final roadType = suggestion.roadType;
    final mainRoad = suggestion.mainRoad;
    final roadChanged = roadType != previous?.roadType || mainRoad != previous?.mainRoad;
    if (roadType != null && mainRoad != null && roadChanged) {
      _useStructuredAddress = true;
      _selectedRoadType = roadType;
      _mainRoadNumberController.text = mainRoad;
    }
    final crossRoad = suggestion.crossRoad;
    if (crossRoad != null && crossRoad != previous?.crossRoad) _crossRoadNumberController.text = crossRoad;
    final plot = suggestion.plot;
    if (plot != null && plot != previous?.plot) _plaqueNumberController.text = plot;
    final neighborhood = suggestion.neighborhood;
    if (neighborhood != null && neighborhood != previous?.neighborhood) {
      _neighborhoodController.text = neighborhood;
    }
    _suggestionApplied = true;
  }

  /// Loading ring at the end of a field the suggestion has not filled yet.
  Widget _searchingRing(String semanticLabel) {
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: DottedSpinner(size: AppSizes.icon, semanticLabel: semanticLabel),
    );
  }

  @override
  void dispose() {
    _mainRoadNumberController.removeListener(_onStructuredFieldChanged);
    _crossRoadNumberController.removeListener(_onStructuredFieldChanged);
    _plaqueNumberController.removeListener(_onStructuredFieldChanged);
    _freeAddressController.dispose();
    _neighborhoodController.dispose();
    _mainRoadNumberController.dispose();
    _crossRoadNumberController.dispose();
    _plaqueNumberController.dispose();
    super.dispose();
  }

  String _buildFormattedAddress() {
    if (_useStructuredAddress) {
      final main = _mainRoadNumberController.text.trim();
      final cross = _crossRoadNumberController.text.trim();
      final plaque = _plaqueNumberController.text.trim();
      if (plaque.isEmpty) {
        return '$_selectedRoadType $main # $cross';
      }
      return '$_selectedRoadType $main # $cross - $plaque';
    }
    return _freeAddressController.text.trim();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final formatted = _buildFormattedAddress();
      widget.onLocationConfirmed(
        coordinates: _coordinates,
        formattedAddress: formatted,
        neighborhood: _neighborhoodController.text.trim(),
        city: _city,
      );
    }
  }

  void _onMapPointConfirmed(Coordinates point) {
    setState(() {
      _coordinates = point;
      _pickingOnMap = false;
    });
    widget.onMapPointSelected?.call(point);
  }

  /// What happened to the typed address and what to do next (HU-28), or null
  /// when there is nothing to say (no search yet, or the form changed since).
  Widget? _outcomeNotice() {
    final outcome = widget.addressOutcome;
    if (outcome == null || _outcomeSignature != _formSignature()) return null;

    final city = _city;
    final (kind, message) = switch (outcome) {
      AddressOutcome.building => (
          NoticeKind.success,
          'Encontramos esa dirección. Revisa que el punto esté sobre el daño y toca "Confirmar ubicación".',
        ),
      AddressOutcome.street => (
          NoticeKind.info,
          'Ubicamos la calle, pero no la puerta. Mueve el punto en el mapa hasta el daño.',
        ),
      AddressOutcome.notFound => (
          NoticeKind.error,
          'No encontramos esa dirección, así que dejamos el punto en el centro de $city. '
              'Revisa cómo la escribiste (ej. Carrera 9 # 5-45) o marca el punto en el mapa.',
        ),
      AddressOutcome.notUnderstood => (
          NoticeKind.error,
          'Parece una dirección, pero no entendemos cómo está escrita. '
              'Prueba con Carrera 9 # 5-45 o marca el punto en el mapa. Dejamos el punto en el centro de $city.',
        ),
      AddressOutcome.serviceFailed => (
          NoticeKind.error,
          'No pudimos buscar la dirección por la conexión. Dejamos el punto en el centro de $city. '
              'Inténtalo de nuevo o márcalo en el mapa.',
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppNotice(kind: kind, message: message),
        if (outcome != AddressOutcome.building)
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              if (outcome == AddressOutcome.serviceFailed)
                TextButton(onPressed: widget.isGeocodingAddress ? null : _submit, child: const Text('Reintentar')),
              TextButton(
                onPressed: () => setState(() => _pickingOnMap = true),
                child: Text(outcome == AddressOutcome.street ? 'Ajustar en el mapa' : 'Marcar en el mapa'),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pickingOnMap) {
      return MapPointSelector(
        coordinates: _coordinates,
        isLocating: widget.isLocating,
        onUseMyLocation: widget.onDetectLocation,
        onConfirmed: _onMapPointConfirmed,
        onCancel: () => setState(() => _pickingOnMap = false),
        availableHeight: widget.availableHeight,
      );
    }

    final theme = Theme.of(context);
    final searchingCrossRoad = widget.isSuggestingAddress;
    final searchingMainRoad = searchingCrossRoad && widget.suggestedAddress == null;
    final suggestionMessage = widget.suggestionMessage;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ubica el daño en la vía',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Verifica el punto del daño en el mapa y confirma la dirección con nomenclatura o punto de referencia.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // GPS Coordinates Card with Real Detection Action
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coordenadas geográficas',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${_coordinates.latitude.toStringAsFixed(5)}°, ${_coordinates.longitude.toStringAsFixed(5)}° ($_city)',
                            style: AppTextStyles.data(size: 13).copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                _SourceLabel(source: widget.coordinatesSource),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _pickingOnMap = true),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Seleccionar ubicación'),
                ),
                if (widget.locationStatusMessage != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.locationStatusMessage!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: widget.locationStatusMessage!.startsWith('GPS detectado')
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Structured Nomenclature vs Reference Point Selector
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Nomenclatura vial')),
                  selected: _useStructuredAddress,
                  onSelected: (val) {
                    if (val) setState(() => _useStructuredAddress = true);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Punto de referencia')),
                  selected: !_useStructuredAddress,
                  onSelected: (val) {
                    if (val) setState(() => _useStructuredAddress = false);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _useStructuredAddress
                ? 'Ejemplo: Carrera 9 # 5-45 (vía, cruce y número de la puerta).'
                : 'Para ubicarlo en el mapa, mejor escribe una dirección como Carrera 9 # 5-45. '
                    'Si es un lugar (frente al parque), marca el punto en el mapa.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),

          if (_suggestionApplied) ...[
            const AppNotice(
              message: 'Actualizamos la dirección según el punto. Revísala antes de continuar.',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (suggestionMessage != null) ...[
            AppNotice(message: suggestionMessage, kind: NoticeKind.error),
            const SizedBox(height: AppSpacing.md),
          ],

          // Structured Nomenclature Form
          if (_useStructuredAddress) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: AppFieldLabel(
                    label: 'Tipo de vía',
                    child: DropdownButtonFormField<String>(
                      // initialValue is read once; the key rebuilds the field
                      // when a GPS suggestion changes the road type.
                      key: ValueKey('road-type-$_selectedRoadType'),
                      initialValue: _selectedRoadType,
                      isExpanded: true,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 13.5,
                        ),
                      ),
                      items: _roadTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRoadType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 5,
                  child: AppTextField(
                    label: 'Vía principal',
                    controller: _mainRoadNumberController,
                    hint: searchingMainRoad
                        ? 'Buscando…'
                        : (_namedRoadTypes.contains(_selectedRoadType) ? 'Ej. 30 o Sur' : 'Ej. 9 o 15 Norte'),
                    suffix: searchingMainRoad ? _searchingRing('Buscando la vía') : null,
                    validator: (v) {
                      if (!_useStructuredAddress) return null;
                      if (v == null || v.trim().isEmpty) {
                        return 'Requerido';
                      }
                      if (!_namedRoadTypes.contains(_selectedRoadType) && !RegExp(r'\d').hasMatch(v)) {
                        return 'Debe incluir número';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Cruce o generadora (#)',
                    controller: _crossRoadNumberController,
                    hint: searchingCrossRoad ? 'Buscando…' : 'Ej. 45 o 2B',
                    prefixIcon: Icons.tag,
                    suffix: searchingCrossRoad ? _searchingRing('Buscando el cruce') : null,
                    validator: (v) {
                      if (!_useStructuredAddress) return null;
                      if (v == null || v.trim().isEmpty) {
                        return 'Requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    label: 'Número o predio (opcional)',
                    controller: _plaqueNumberController,
                    hint: 'Ej. 20 o 04',
                    prefixIcon: Icons.remove,
                    validator: (v) {
                      // Placa is optional per Colombian road damage context
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Live Address Preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Dirección: ${_buildFormattedAddress()}',
                      style: AppTextStyles.data(size: 12).copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Free-form Reference Point
            AppTextField(
              label: 'Punto de referencia o dirección',
              controller: _freeAddressController,
              hint: 'Ej. Frente a la estación de servicio Bellavista',
              prefixIcon: Icons.signpost_outlined,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (_useStructuredAddress) return null;
                try {
                  ReportValidators.validateAddress(v ?? '');
                  return null;
                } on Exception catch (e) {
                  return e.toString().replaceFirst('Exception: ', '');
                }
              },
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          // Neighborhood / Sector input with strict validation
          AppTextField(
            label: 'Barrio o sector',
            controller: _neighborhoodController,
            hint: 'Ej. Granada, Tequendama, Centro',
            prefixIcon: Icons.holiday_village_outlined,
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              try {
                ReportValidators.validateNeighborhood(v ?? '');
                return null;
              } on Exception catch (e) {
                return e.toString().replaceFirst('Exception: ', '');
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_outcomeNotice() case final notice?) ...[
            notice,
            const SizedBox(height: AppSpacing.md),
          ],
          PrimaryButton(
            label: 'Confirmar ubicación',
            loadingLabel: 'Buscando la dirección…',
            isLoading: widget.isGeocodingAddress,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Says, in words and with an icon, where the point comes from (HU-28): never
/// color alone. A GPS reading and a map point are exact; the rest is an estimate.
class _SourceLabel extends StatelessWidget {
  final LocationSource source;

  const _SourceLabel({required this.source});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, text) = switch (source) {
      LocationSource.gps => (Icons.gps_fixed, 'Tu ubicación (GPS)'),
      LocationSource.mapPoint => (Icons.push_pin_outlined, 'Punto marcado en el mapa'),
      LocationSource.address => (Icons.edit_location_alt_outlined, 'Aproximada: según la dirección'),
      LocationSource.cityCenter => (Icons.location_city_outlined, 'Aproximada: centro de la ciudad'),
    };

    return Row(
      children: [
        Icon(icon, size: AppSizes.icon - 4, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs + 2),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

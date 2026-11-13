import 'package:flutter/material.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_text_styles.dart';
import 'package:vigia_app/core/widgets/app_text_field.dart';
import 'package:vigia_app/core/widgets/primary_button.dart';
import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';

/// Step 1: Location georeferencing and address confirmation (HU-07).
class LocationPinPicker extends StatefulWidget {
  final Coordinates? initialCoordinates;
  final String? initialAddress;
  final String? initialNeighborhood;
  final String? initialCity;
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
    required this.onLocationConfirmed,
  });

  @override
  State<LocationPinPicker> createState() => _LocationPinPickerState();
}

class _LocationPinPickerState extends State<LocationPinPicker> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressController;
  late final TextEditingController _neighborhoodController;
  late Coordinates _coordinates;
  late String _city;

  @override
  void initState() {
    super.initState();
    _coordinates = widget.initialCoordinates ??
        const Coordinates(latitude: 3.4516, longitude: -76.5320); // Cali center default
    _city = widget.initialCity ?? 'Cali';
    _addressController = TextEditingController(text: widget.initialAddress ?? '');
    _neighborhoodController =
        TextEditingController(text: widget.initialNeighborhood ?? '');
  }

  @override
  void dispose() {
    _addressController.dispose();
    _neighborhoodController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onLocationConfirmed(
        coordinates: _coordinates,
        formattedAddress: _addressController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _city,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ubica el daño en el mapa',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Verifica la posición exacta y complementa con la dirección y barrio.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Georeferenced coordinates box
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coordenadas GPS',
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
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Dirección o punto de referencia',
            controller: _addressController,
            hint: 'Ej. Calle 5 con Carrera 44',
            prefixIcon: Icons.signpost_outlined,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Escribe la dirección o punto de referencia.';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Barrio o sector',
            controller: _neighborhoodController,
            hint: 'Ej. Tequendama',
            prefixIcon: Icons.holiday_village_outlined,
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Escribe el barrio o sector.';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Confirmar ubicación',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

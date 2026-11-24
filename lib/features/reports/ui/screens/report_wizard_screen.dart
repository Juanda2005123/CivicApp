import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_text_styles.dart';
import 'package:vigia_app/core/widgets/app_notice.dart';
import 'package:vigia_app/core/widgets/app_text_field.dart';
import 'package:vigia_app/core/widgets/location_blocked_dialog.dart';
import 'package:vigia_app/core/widgets/primary_button.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_category.dart';
import '../bloc/report_wizard_bloc.dart';
import '../bloc/report_wizard_event.dart';
import '../bloc/report_wizard_state.dart';
import '../widgets/location_pin_picker.dart';
import '../widgets/nearby_incidents_modal.dart';
import '../widgets/photo_evidence_box.dart';
import '../widgets/severity_chip_selector.dart';
import '../widgets/wizard_progress_header.dart';

/// 5-Step guided wizard for reporting road infrastructure damage (HU-06 to HU-12).
class ReportWizardScreen extends StatefulWidget {
  const ReportWizardScreen({super.key});

  @override
  State<ReportWizardScreen> createState() => _ReportWizardScreenState();
}

class _ReportWizardScreenState extends State<ReportWizardScreen> {
  // Step 2 state
  int? _selectedCategoryId;
  IncidentSeverity _selectedSeverity = IncidentSeverity.medium;

  // Step 4 state
  final _step4FormKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dimensionsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dimensionsController.dispose();
    super.dispose();
  }

  void _onBack(BuildContext context, ReportWizardState state) {
    if (state.currentStep > 1) {
      context.read<ReportWizardBloc>().add(StepNavigated(state.currentStep - 1));
    } else {
      _handleExit(context, state);
    }
  }

  void _handleExit(BuildContext context, ReportWizardState state) {
    if (!state.hasDraftData) {
      Navigator.of(context).pop();
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('¿Descartar este reporte?'),
        content: const Text(
          'Si sales ahora, se perderán todos los datos que has ingresado en el asistente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop(true);
              Navigator.of(context).pop();
            },
            child: const Text('Descartar reporte'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A blocked permission (HU-29) opens a modal once per "Centrar en mi ubicación" attempt: the
    // flag goes false while locating and back to true when it fails again.
    return BlocListener<ReportWizardBloc, ReportWizardState>(
      listenWhen: (previous, current) => !previous.isLocationBlocked && current.isLocationBlocked,
      listener: (context, state) {
        final message = state.locationStatusMessage;
        if (message == null) return;
        final bloc = context.read<ReportWizardBloc>();
        showLocationBlockedDialog(
          context,
          message: message,
          onOpenSettings: () => bloc.add(LocationSettingsRequested()),
        );
      },
      child: _buildWizard(context),
    );
  }

  Widget _buildWizard(BuildContext context) {
    return BlocConsumer<ReportWizardBloc, ReportWizardState>(
      listener: (context, state) {
        if (state.status == WizardStatus.success) {
          if (state.isEndorsedNearby) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Apoyaste el reporte existente con éxito!')),
            );
            Navigator.of(context).pop();
          } else if (state.isOwnNearbyReport) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ese reporte ya es tuyo, así que no suma un apoyo. No hace falta reportarlo otra vez.'),
              ),
            );
            Navigator.of(context).pop();
          } else if (state.publishedIncident != null) {
            _showPublishedDialog(context, state.publishedIncident!);
          }
        }
      },
      builder: (context, state) {
        return PopScope(
          canPop: !state.hasDraftData,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleExit(context, state);
          },
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  WizardProgressHeader(
                    currentStep: state.currentStep,
                    onBack: () => _onBack(context, state),
                    onClose: () => _handleExit(context, state),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: AppNotice(
                        message: state.errorMessage!,
                        kind: NoticeKind.error,
                      ),
                    ),
                  Expanded(
                    // The viewport height lets the Step 1 map fill the screen.
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: _buildCurrentStep(
                          context,
                          state,
                          constraints.maxHeight - AppSpacing.md * 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStep(BuildContext context, ReportWizardState state, double availableHeight) {
    switch (state.currentStep) {
      case 1:
        return LocationPinPicker(
          initialCoordinates: state.coordinates,
          initialAddress: state.formattedAddress,
          initialNeighborhood: state.neighborhood,
          initialCity: state.city,
          isLocating: state.isLocating,
          // A blocked permission is explained in the modal instead.
          locationStatusMessage: state.isLocationBlocked ? null : state.locationStatusMessage,
          suggestedAddress: state.suggestedAddress,
          isSuggestingAddress: state.isSuggestingAddress,
          suggestionMessage: state.addressSuggestionMessage,
          coordinatesSource: state.coordinatesSource,
          isGeocodingAddress: state.isGeocodingAddress,
          addressOutcome: state.addressOutcome,
          availableHeight: availableHeight,
          onDetectLocation: () {
            context.read<ReportWizardBloc>().add(CurrentLocationRequested());
          },
          onMapPointSelected: (point) {
            context.read<ReportWizardBloc>().add(MapPointSelected(point));
          },
          onLocationConfirmed: ({
            required coordinates,
            required formattedAddress,
            required neighborhood,
            required city,
          }) {
            context.read<ReportWizardBloc>().add(LocationPitched(
                  coordinates: coordinates,
                  formattedAddress: formattedAddress,
                  neighborhood: neighborhood,
                  city: city,
                ));
          },
        );

      case 2:
        return _buildStep2Classification(context, state);

      case 3:
        return _buildStep3Photos(context, state);

      case 4:
        return _buildStep4Details(context, state);

      case 5:
        return _buildStep5Summary(context, state);

      default:
        return const SizedBox.shrink();
    }
  }

  IconData _getCategoryIcon(IncidentCategory cat) {
    final lower = cat.name.toLowerCase();
    if (lower.contains('hueco') || lower.contains('bache') || lower.contains('pothole')) {
      return Icons.remove_road_outlined;
    }
    if (lower.contains('semáforo') || lower.contains('semaforo') || lower.contains('traffic')) {
      return Icons.traffic_outlined;
    }
    if (lower.contains('obra') || lower.contains('abandoned')) {
      return Icons.construction_outlined;
    }
    if (lower.contains('andén') || lower.contains('anden') || lower.contains('sidewalk')) {
      return Icons.directions_walk_outlined;
    }
    if (lower.contains('agua') || lower.contains('fuga') || lower.contains('water') || lower.contains('alcantarilla')) {
      return Icons.water_drop_outlined;
    }
    if (lower.contains('señal') || lower.contains('senal') || lower.contains('signage')) {
      return Icons.signpost_outlined;
    }
    return Icons.report_problem_outlined;
  }

  // STEP 2: Classification and Severity (HU-08/HU-09)
  Widget _buildStep2Classification(BuildContext context, ReportWizardState state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Qué tipo de daño es?',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Elige la categoría del problema y su gravedad percibida.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Categoría del daño',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (state.status == WizardStatus.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.xs,
              mainAxisSpacing: AppSpacing.xs,
              childAspectRatio: 3.1,
            ),
            itemCount: state.categories.length,
            itemBuilder: (context, index) {
              final cat = state.categories[index];
              final isSelected = (_selectedCategoryId ?? state.selectedCategoryId) == cat.id;
              final iconData = _getCategoryIcon(cat);

              return InkWell(
                onTap: () {
                  setState(() => _selectedCategoryId = cat.id);
                },
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.28),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.onPrimary.withValues(alpha: 0.22)
                              : theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          iconData,
                          size: 15,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Expanded(
                        child: Text(
                          cat.displayNameSpanish,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 10.5,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Gravedad del daño',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        SeverityChipSelector(
          selectedSeverity: _selectedSeverity,
          onSeverityChanged: (s) => setState(() => _selectedSeverity = s),
        ),
        if (state.nearbyIncidents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: theme.colorScheme.error),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    state.nearbyIncidents.length == 1
                        ? 'Hay 1 daño cercano de este tipo.'
                        : 'Hay ${state.nearbyIncidents.length} daños cercanos de este tipo.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    NearbyIncidentsModal.show(
                      context,
                      nearbyIncidents: state.nearbyIncidents,
                      onEndorse: (id) {
                        context.read<ReportWizardBloc>().add(NearbyReportEndorsed(id));
                      },
                      onContinueDraft: () {
                        context.read<ReportWizardBloc>().add(NearbyCheckDismissed());
                      },
                    );
                  },
                  child: const Text('Ver daños'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: 'Continuar',
          isLoading: state.isCheckingNearby,
          onPressed: () {
            final catId = _selectedCategoryId ?? state.selectedCategoryId;
            if (catId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Por favor selecciona una categoría.')),
              );
              return;
            }
            context.read<ReportWizardBloc>().add(CategoryAndSeveritySelected(
                  categoryId: catId,
                  severity: _selectedSeverity,
                ));
          },
        ),
      ],
    );
  }

  // STEP 3: Photos (HU-10)
  Widget _buildStep3Photos(BuildContext context, ReportWizardState state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adjunta fotos de evidencia',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Puedes agregar hasta 3 fotos (máx. 5 MB cada una). Este paso es opcional.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PhotoEvidenceBox(
          photos: state.photos,
          onPickPhoto: () => _showPhotoSourceSheet(context),
          onRemovePhoto: (index) {
            context.read<ReportWizardBloc>().add(PhotoRemoved(index));
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: state.photos.isEmpty ? 'Omitir fotos y continuar' : 'Continuar con la descripción',
          onPressed: () {
            context.read<ReportWizardBloc>().add(const StepNavigated(4));
          },
        ),
      ],
    );
  }

  void _showPhotoSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Tomar foto con la cámara'),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    context.read<ReportWizardBloc>().add(const PhotoPickRequested(fromCamera: true));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Elegir foto de la galería / archivos'),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    context.read<ReportWizardBloc>().add(const PhotoPickRequested(fromCamera: false));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // STEP 4: Description & Details (HU-11)
  Widget _buildStep4Details(BuildContext context, ReportWizardState state) {
    final theme = Theme.of(context);

    return Form(
      key: _step4FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe el problema',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Escribe un título claro y explica cómo afecta la vía y el tránsito.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Título del reporte',
            controller: _titleController..text = _titleController.text.isEmpty ? state.title : _titleController.text,
            hint: 'Ej. Hueco profundo en carril derecho',
            textCapitalization: TextCapitalization.sentences,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'El título es obligatorio.';
              if (v.trim().length < 5) return 'El título debe tener al menos 5 caracteres.';
              if (v.trim().length > 180) return 'El título no puede superar 180 caracteres.';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Descripción detallada',
            controller: _descriptionController
              ..text = _descriptionController.text.isEmpty ? state.description : _descriptionController.text,
            hint: 'Explica el riesgo, profundidad o daño en el pavimento...',
            textCapitalization: TextCapitalization.sentences,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'La descripción es obligatoria.';
              if (v.trim().length < 10) return 'La descripción debe tener al menos 10 caracteres.';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Dimensiones aproximadas (opcional)',
            controller: _dimensionsController
              ..text = _dimensionsController.text.isEmpty ? (state.dimensions ?? '') : _dimensionsController.text,
            hint: 'Ej. ~1.5m de largo x 20cm de profundidad',
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Revisar reporte',
            onPressed: () {
              if (_step4FormKey.currentState?.validate() ?? false) {
                context.read<ReportWizardBloc>().add(DetailsSubmitted(
                      title: _titleController.text.trim(),
                      description: _descriptionController.text.trim(),
                      dimensions: _dimensionsController.text.trim().isEmpty
                          ? null
                          : _dimensionsController.text.trim(),
                    ));
              }
            },
          ),
        ],
      ),
    );
  }

  // STEP 5: Summary and Publish (HU-12)
  Widget _buildStep5Summary(BuildContext context, ReportWizardState state) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revisa tu reporte',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Verifica los datos antes de publicar para obtener tu código público.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      state.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      state.severity.labelSpanish,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                state.description,
                style: theme.textTheme.bodyMedium,
              ),
              if (state.dimensions != null && state.dimensions!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Dimensiones: ${state.dimensions}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Divider(height: AppSpacing.lg),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${state.formattedAddress}, ${state.neighborhood} (${state.city})',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.photo_camera_outlined, size: 18),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Fotos adjuntas: ${state.photos.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.workspace_premium, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Al publicar este reporte recibirás +100 XP en tu perfil cívico.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Publicar reporte (+100 XP)',
          loadingLabel: 'Publicando reporte...',
          isLoading: state.status == WizardStatus.submitting,
          onPressed: () {
            context.read<ReportWizardBloc>().add(ReportSubmitConfirmed());
          },
        ),
      ],
    );
  }

  void _showPublishedDialog(BuildContext context, Incident incident) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('¡Reporte publicado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tu reporte ha quedado registrado exitosamente.'),
            const SizedBox(height: AppSpacing.md),
            const Text('Código de seguimiento:'),
            Text(
              incident.trackingCode,
              style: AppTextStyles.data(size: 18).copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Has ganado +100 XP de participación cívica.'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              Navigator.of(context).pop(incident);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}

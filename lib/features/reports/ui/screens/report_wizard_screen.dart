import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/core/theme/app_text_styles.dart';
import 'package:vigia_app/core/widgets/app_notice.dart';
import 'package:vigia_app/core/widgets/app_text_field.dart';
import 'package:vigia_app/core/widgets/primary_button.dart';
import 'package:vigia_app/features/reports/domain/entities/incident.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';
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
  final TextEditingController _categorySearchController = TextEditingController();

  // Step 4 state
  final _step4FormKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dimensionsController = TextEditingController();

  @override
  void dispose() {
    _categorySearchController.dispose();
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
    return BlocConsumer<ReportWizardBloc, ReportWizardState>(
      listener: (context, state) {
        if (state.status == WizardStatus.success) {
          if (state.isEndorsedNearby) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Apoyaste el reporte existente con éxito!')),
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildCurrentStep(context, state),
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

  Widget _buildCurrentStep(BuildContext context, ReportWizardState state) {
    switch (state.currentStep) {
      case 1:
        return LocationPinPicker(
          initialCoordinates: state.coordinates,
          initialAddress: state.formattedAddress,
          initialNeighborhood: state.neighborhood,
          initialCity: state.city,
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

  // STEP 2: Classification and Severity (HU-08/HU-09)
  Widget _buildStep2Classification(BuildContext context, ReportWizardState state) {
    final theme = Theme.of(context);
    final query = _categorySearchController.text.toLowerCase().trim();

    final filteredCategories = state.categories.where((cat) {
      if (query.isEmpty) return true;
      return cat.name.toLowerCase().contains(query);
    }).toList();

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
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _categorySearchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Buscar categoría...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Categoría del daño',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.status == WizardStatus.loading)
          const Center(child: CircularProgressIndicator())
        else if (filteredCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'No encontramos categorías que coincidan.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 2.3,
            ),
            itemCount: filteredCategories.length,
            itemBuilder: (context, index) {
              final cat = filteredCategories[index];
              final isSelected = (_selectedCategoryId ?? state.selectedCategoryId) == cat.id;

              return InkWell(
                onTap: () {
                  setState(() => _selectedCategoryId = cat.id);
                },
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 22,
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          cat.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Gravedad del daño',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        SeverityChipSelector(
          selectedSeverity: _selectedSeverity,
          onSeverityChanged: (s) => setState(() => _selectedSeverity = s),
        ),
        if (state.nearbyIncidents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: theme.colorScheme.error),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: theme.colorScheme.error),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Hay ${state.nearbyIncidents.length} daños cercanos de este tipo.',
                    style: theme.textTheme.bodyMedium?.copyWith(
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
        const SizedBox(height: AppSpacing.lg),
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
          onPickPhoto: () {
            // Emulate picking or provide sample photo bytes for the wizard
            final sampleBytes = Uint8List.fromList(List.filled(200, 1));
            final newPhotos = List<PickedPhoto>.from(state.photos)
              ..add(PickedPhoto(
                bytes: sampleBytes,
                extension: 'jpg',
                sizeInBytes: 200,
              ));
            context.read<ReportWizardBloc>().add(PhotosUpdated(newPhotos));
          },
          onRemovePhoto: (index) {
            final newPhotos = List<PickedPhoto>.from(state.photos)..removeAt(index);
            context.read<ReportWizardBloc>().add(PhotosUpdated(newPhotos));
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dropdown_field.dart';
import '../../../../core/widgets/app_notice.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/dotted_spinner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/incident.dart';
import '../bloc/edit_report_bloc.dart';
import '../bloc/edit_report_event.dart';
import '../bloc/edit_report_state.dart';
import '../widgets/editable_photos_box.dart';
import '../widgets/severity_chip_selector.dart';

/// Edit form of the author's report (HU-18): category, severity, photos, title,
/// description and dimensions. The tracking code, the place and the status are
/// not editable. It pops with `true` once the changes are saved, so the caller
/// reads the report again. If the 30 minutes ended with the screen open, the
/// server refuses and its message appears here with the form intact (criterion 5).
class EditReportScreen extends StatefulWidget {
  /// The report to edit; when null it comes from the route arguments.
  final Incident? incident;

  const EditReportScreen({super.key, this.incident});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dimensionsController = TextEditingController();
  Incident? _incident;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_incident != null) return;
    final incident = widget.incident ?? ModalRoute.of(context)?.settings.arguments as Incident?;
    if (incident == null) return;
    _incident = incident;
    _titleController.text = incident.title;
    _descriptionController.text = incident.description;
    _dimensionsController.text = incident.estimatedDimensions ?? '';
    context.read<EditReportBloc>().add(EditReportStarted(incident));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dimensionsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final dimensions = _dimensionsController.text.trim();
    context.read<EditReportBloc>().add(EditSubmitted(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dimensions: dimensions.isEmpty ? null : dimensions,
        ));
  }

  void _showPhotoSourceSheet() {
    final bloc = context.read<EditReportBloc>();
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Tomar foto con la cámara'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                bloc.add(const EditPhotoPickRequested(fromCamera: true));
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.images),
              title: const Text('Elegir foto de la galería'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                bloc.add(const EditPhotoPickRequested(fromCamera: false));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar reporte', style: AppTextStyles.appBarTitle),
        centerTitle: false,
      ),
      body: BlocConsumer<EditReportBloc, EditReportState>(
        listenWhen: (previous, current) =>
            previous.status != current.status && current.status == EditReportStatus.saved,
        listener: (context, state) => Navigator.of(context).pop(true),
        builder: (context, state) {
          if (state.incident == null || state.status == EditReportStatus.loading) {
            return const Center(child: DottedSpinner(size: 36, semanticLabel: 'Cargando el formulario'));
          }
          if (state.status == EditReportStatus.failure) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppNotice(
                    kind: NoticeKind.error,
                    message: state.errorMessage ?? 'No pudimos cargar el formulario.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Reintentar',
                    onPressed: () => context.read<EditReportBloc>().add(EditReportStarted(state.incident!)),
                  ),
                ],
              ),
            );
          }
          return _buildForm(context, state);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, EditReportState state) {
    final theme = Theme.of(context);
    final bloc = context.read<EditReportBloc>();
    final saving = state.status == EditReportStatus.saving;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'El código ${state.incident!.trackingCode} y la ubicación no se pueden cambiar.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppDropdownField<int>(
              label: 'Categoría del daño',
              hint: 'Elige una categoría',
              value: state.categoryId,
              entries: [
                for (final category in state.categories)
                  DropdownMenuEntry<int>(value: category.id, label: category.displayNameSpanish),
              ],
              onChanged: saving ? null : (id) => id == null ? null : bloc.add(EditCategorySelected(id)),
              validator: (id) => id == null ? 'Elige una categoría.' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Gravedad', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SeverityChipSelector(
              selectedSeverity: state.severity,
              onSeverityChanged: (severity) {
                if (!saving) bloc.add(EditSeveritySelected(severity));
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Título del reporte',
              controller: _titleController,
              hint: 'Ej. Hueco profundo en carril derecho',
              enabled: !saving,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'El título es obligatorio.';
                if (text.length < 5) return 'El título debe tener al menos 5 caracteres.';
                if (text.length > 180) return 'El título no puede superar 180 caracteres.';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Descripción detallada',
              controller: _descriptionController,
              hint: 'Explica el riesgo, la profundidad o el daño en el pavimento…',
              enabled: !saving,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'La descripción es obligatoria.';
                if (text.length < 10) return 'La descripción debe tener al menos 10 caracteres.';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Dimensiones aproximadas (opcional)',
              controller: _dimensionsController,
              hint: 'Ej. ~1.5 m de largo x 20 cm de profundidad',
              enabled: !saving,
            ),
            const SizedBox(height: AppSpacing.lg),
            EditablePhotosBox(
              keptPhotos: state.keptPhotos,
              addedPhotos: state.addedPhotos,
              onRemoveKept: (photo) => bloc.add(EditKeptPhotoRemoved(photo.id)),
              onRemoveAdded: (index) => bloc.add(EditAddedPhotoRemoved(index)),
              onAdd: saving ? null : _showPhotoSourceSheet,
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppNotice(kind: NoticeKind.error, message: state.errorMessage!),
            ],
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Guardar cambios',
              loadingLabel: 'Guardando…',
              isLoading: saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/incident_photo.dart';
import '../../domain/entities/picked_photo.dart';
import '../../domain/validators/report_validators.dart';

/// The photos of a report being edited (HU-18): the ones it already has and the
/// ones just picked, up to 3 together. Each one has a remove button; the next
/// free slot adds a photo. Pure UI: it knows no bloc nor SDK.
class EditablePhotosBox extends StatelessWidget {
  final List<IncidentPhoto> keptPhotos;
  final List<PickedPhoto> addedPhotos;
  final ValueChanged<IncidentPhoto> onRemoveKept;
  final ValueChanged<int> onRemoveAdded;
  final VoidCallback? onAdd;

  const EditablePhotosBox({
    super.key,
    required this.keptPhotos,
    required this.addedPhotos,
    required this.onRemoveKept,
    required this.onRemoveAdded,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const max = ReportValidators.maxPhotosAllowed;
    final count = keptPhotos.length + addedPhotos.length;

    final slots = <Widget>[
      for (final photo in keptPhotos)
        _PhotoSlot(
          label: 'Foto del reporte',
          onRemove: () => onRemoveKept(photo),
          child: Image.network(
            photo.fileUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const _BrokenPhoto(),
          ),
        ),
      for (final (index, photo) in addedPhotos.indexed)
        _PhotoSlot(
          label: 'Foto nueva',
          onRemove: () => onRemoveAdded(index),
          child: Image.memory(
            photo.bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const _BrokenPhoto(),
          ),
        ),
      if (count < max) _AddSlot(onTap: onAdd),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Fotos ($count/$max)', style: theme.textTheme.titleSmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var i = 0; i < max; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(child: i < slots.length ? slots[i] : const AspectRatio(aspectRatio: 1, child: SizedBox())),
            ],
          ],
        ),
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final Widget child;

  const _PhotoSlot({required this.label, required this.onRemove, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            image: true,
            label: label,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadii.small,
                border: Border.all(color: scheme.outlineVariant),
                color: scheme.surfaceContainerHighest,
              ),
              child: ClipRRect(borderRadius: AppRadii.small, child: child),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              tooltip: 'Quitar foto',
              onPressed: onRemove,
              style: IconButton.styleFrom(backgroundColor: scheme.surface, foregroundColor: scheme.onSurface),
              icon: const Icon(Icons.close, size: AppSizes.icon),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSlot extends StatelessWidget {
  final VoidCallback? onTap;

  const _AddSlot({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1,
      child: Semantics(
        button: true,
        label: 'Agregar foto',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.small,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: AppRadii.small,
              border: Border.all(color: scheme.outline),
              color: scheme.surfaceContainerLow,
            ),
            child: Center(child: Icon(Icons.add_a_photo_outlined, size: AppSizes.iconLarge, color: scheme.primary)),
          ),
        ),
      ),
    );
  }
}

class _BrokenPhoto extends StatelessWidget {
  const _BrokenPhoto();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: AppSizes.iconLarge,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

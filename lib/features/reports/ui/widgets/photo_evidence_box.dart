import 'package:flutter/material.dart';
import 'package:vigia_app/core/theme/app_spacing.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';

/// Renders up to 3 photographic evidence slots with thumbnail preview,
/// primary cover indicator, and remove actions (HU-10).
/// Pure UI component with zero SDK dependencies.
class PhotoEvidenceBox extends StatelessWidget {
  static const int maxPhotos = 3;

  final List<PickedPhoto> photos;
  final VoidCallback? onPickPhoto;
  final ValueChanged<int> onRemovePhoto;

  const PhotoEvidenceBox({
    super.key,
    required this.photos,
    this.onPickPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMore = photos.length < maxPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Evidencia fotográfica (${photos.length}/$maxPhotos)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (photos.isEmpty)
              Text(
                'Opcional',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var i = 0; i < maxPhotos; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: i < photos.length
                    ? _PhotoThumbnail(
                        photo: photos[i],
                        isPrimary: i == 0,
                        onRemove: () => onRemovePhoto(i),
                      )
                    : _EmptyPhotoSlot(
                        enabled: canAddMore && i == photos.length,
                        onTap: canAddMore && i == photos.length ? onPickPhoto : null,
                      ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final PickedPhoto photo;
  final bool isPrimary;
  final VoidCallback onRemove;

  const _PhotoThumbnail({
    required this.photo,
    required this.isPrimary,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
              color: theme.colorScheme.surface,
            ),
            clipBehavior: Clip.antiAlias,
            child: photo.bytes.isNotEmpty
                ? Image.memory(
                    photo.bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 28,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : const Icon(Icons.image, size: 32),
          ),
          if (isPrimary)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Principal',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 4,
            top: 4,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPhotoSlot extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;

  const _EmptyPhotoSlot({
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 1.0,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          decoration: BoxDecoration(
            color: enabled
                ? theme.colorScheme.surface
                : theme.colorScheme.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: enabled
                  ? theme.colorScheme.outline
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                size: 26,
                color: enabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 4),
              Text(
                'Agregar',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: enabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

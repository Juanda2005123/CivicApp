import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import '../entities/picked_photo.dart';

/// Single source of truth for report validation rules across the domain.
class ReportValidators {
  static const int minTitleLength = 5;
  static const int maxTitleLength = 180;
  static const int minDescriptionLength = 10;
  static const int maxPhotosAllowed = 3;
  static const int maxPhotoSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedPhotoExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  // Continental Colombia bounding box (RN-12)
  static const double minLatitude = -4.2;
  static const double maxLatitude = 13.5;
  static const double minLongitude = -79.0;
  static const double maxLongitude = -66.8;

  /// Validates the report title (RN-01).
  static void validateTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw Exception('El título del reporte es obligatorio.');
    }
    if (trimmed.length < minTitleLength) {
      throw Exception('El título debe tener al menos $minTitleLength caracteres.');
    }
    if (trimmed.length > maxTitleLength) {
      throw Exception('El título no puede superar los $maxTitleLength caracteres.');
    }
  }

  /// Validates the report description (RN-01).
  static void validateDescription(String description) {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      throw Exception('La descripción del reporte es obligatoria.');
    }
    if (trimmed.length < minDescriptionLength) {
      throw Exception('La descripción debe tener al menos $minDescriptionLength caracteres.');
    }
  }

  /// Validates geographical coordinates within national boundaries (RN-12).
  static void validateCoordinates(Coordinates coordinates) {
    final lat = coordinates.latitude;
    final lng = coordinates.longitude;

    if (lat < minLatitude || lat > maxLatitude || lng < minLongitude || lng > maxLongitude) {
      throw Exception('Las coordenadas deben encontrarse dentro del territorio colombiano.');
    }
  }

  /// Validates formatted address (RN-01).
  static void validateAddress(String address) {
    if (address.trim().isEmpty) {
      throw Exception('La dirección o punto de referencia es obligatoria.');
    }
  }

  /// Validates neighborhood / sector (RN-01).
  static void validateNeighborhood(String neighborhood) {
    if (neighborhood.trim().isEmpty) {
      throw Exception('El barrio o sector es obligatorio.');
    }
  }

  /// Validates photographic evidence count, size, and file formats (RN-02).
  static void validatePhotos(List<PickedPhoto> photos) {
    if (photos.length > maxPhotosAllowed) {
      throw Exception('No puedes adjuntar más de $maxPhotosAllowed fotos por reporte.');
    }

    for (final photo in photos) {
      if (photo.sizeInBytes > maxPhotoSizeBytes) {
        throw Exception('Cada fotografía debe pesar menos de 5 MB.');
      }
      final ext = photo.extension.toLowerCase().replaceAll('.', '');
      if (!allowedPhotoExtensions.contains(ext)) {
        throw Exception('Formato no compatible. Solo se permiten imágenes JPG, PNG o WebP.');
      }
    }
  }
}

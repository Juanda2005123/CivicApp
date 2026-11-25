import 'dart:typed_data';

import '../repositories/profile_repository.dart';

/// Validates avatar format (JPG, PNG, WebP) and size (max 5 MB) before
/// uploading to Supabase Storage (HU-05).
class UpdateAvatarUseCase {
  static const int maxBytes = 5 * 1024 * 1024;
  static const Set<String> allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  final ProfileRepository _profiles;

  UpdateAvatarUseCase(this._profiles);

  Future<String> call({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) {
    final cleanExt = extension.toLowerCase().replaceAll('.', '');
    if (!allowedExtensions.contains(cleanExt)) {
      throw Exception('Solo aceptamos imágenes JPG, PNG o WebP.');
    }
    if (bytes.length > maxBytes) {
      throw Exception('La imagen supera el límite de 5 MB.');
    }
    return _profiles.updateAvatar(userId: userId, bytes: bytes, extension: cleanExt);
  }
}

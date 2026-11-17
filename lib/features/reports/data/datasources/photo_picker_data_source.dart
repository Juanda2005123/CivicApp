import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../domain/entities/picked_photo.dart';

/// The only class in the reports feature that interacts with the [ImagePicker] SDK.
class PhotoPickerDataSource {
  final ImagePicker _picker;

  PhotoPickerDataSource([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  /// Captures or picks an image, scaling down high-resolution camera captures
  /// (e.g. 48 MP sensors) to Full HD at 80% JPEG quality to ensure sizes well under 5 MB.
  Future<PickedPhoto?> pickPhoto({bool fromCamera = false}) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (file == null) return null;

      final Uint8List bytes = await file.readAsBytes();
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : 'jpg';

      return PickedPhoto(
        bytes: bytes,
        extension: ext.isNotEmpty ? ext : 'jpg',
        sizeInBytes: bytes.length,
        localPath: file.path,
      );
    } catch (_) {
      return null;
    }
  }
}

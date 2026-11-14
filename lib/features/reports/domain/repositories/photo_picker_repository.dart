import '../entities/picked_photo.dart';

/// Contract for acquiring photographic evidence from device sensors or storage.
abstract class PhotoPickerRepository {
  /// Picks an image file and returns its compressed [PickedPhoto], or null if cancelled.
  Future<PickedPhoto?> pickPhoto({bool fromCamera = false});
}

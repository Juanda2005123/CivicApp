import '../entities/picked_photo.dart';
import '../validators/report_validators.dart';
import 'pick_photo_usecase.dart';

/// Picks the repair photo of a resolution proposal (HU-25) and checks it at
/// once. Completes with null when the citizen cancels.
class PickResolutionPhotoUseCase {
  final PickPhotoUseCase _pickPhoto;

  PickResolutionPhotoUseCase(this._pickPhoto);

  Future<PickedPhoto?> call({bool fromCamera = false}) async {
    final photo = await _pickPhoto(fromCamera: fromCamera);
    if (photo == null) return null;
    ReportValidators.validatePhotos([photo]);
    return photo;
  }
}

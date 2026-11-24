import '../entities/picked_photo.dart';
import '../validators/report_validators.dart';
import 'pick_photo_usecase.dart';

/// Picks the photo of a comment (HU-17) and checks it at once, so the citizen
/// learns that it is too big or the wrong format before writing the rest.
/// Completes with null when the citizen cancels.
class PickCommentPhotoUseCase {
  final PickPhotoUseCase _pickPhoto;

  PickCommentPhotoUseCase(this._pickPhoto);

  Future<PickedPhoto?> call({bool fromCamera = false}) async {
    final photo = await _pickPhoto(fromCamera: fromCamera);
    if (photo == null) return null;
    ReportValidators.validatePhotos([photo]);
    return photo;
  }
}

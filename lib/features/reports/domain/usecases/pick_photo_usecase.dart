import '../entities/picked_photo.dart';
import '../repositories/photo_picker_repository.dart';

/// Interactor for selecting and preprocessing photographic evidence.
class PickPhotoUseCase {
  final PhotoPickerRepository _repository;

  PickPhotoUseCase(this._repository);

  Future<PickedPhoto?> call({bool fromCamera = false}) {
    return _repository.pickPhoto(fromCamera: fromCamera);
  }
}

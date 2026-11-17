import '../../domain/entities/picked_photo.dart';
import '../../domain/repositories/photo_picker_repository.dart';
import '../datasources/photo_picker_data_source.dart';

/// Implements [PhotoPickerRepository] by delegating to [PhotoPickerDataSource].
class PhotoPickerRepositoryImpl implements PhotoPickerRepository {
  final PhotoPickerDataSource _dataSource;

  PhotoPickerRepositoryImpl(this._dataSource);

  @override
  Future<PickedPhoto?> pickPhoto({bool fromCamera = false}) {
    return _dataSource.pickPhoto(fromCamera: fromCamera);
  }
}

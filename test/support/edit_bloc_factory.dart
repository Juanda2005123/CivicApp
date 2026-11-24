import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/reports/domain/entities/incident_category.dart';
import 'package:vigia_app/features/reports/domain/repositories/incident_repository.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_categories_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/pick_photo_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/update_incident_usecase.dart';
import 'package:vigia_app/features/reports/ui/bloc/edit_report_bloc.dart';

import 'fakes.dart';

/// The categories the edit form lists.
const editCategories = [
  IncidentCategory(id: 1, name: 'Hueco', icon: 'pothole'),
  IncidentCategory(id: 2, name: 'Semáforo', icon: 'traffic'),
];

/// The edit Bloc wired to fakes. By default citizen `me` is signed in; with
/// [guest] nobody is. [picker] answers the photo the citizen picks.
EditReportBloc buildEditBloc(
  IncidentRepository repository, {
  bool guest = false,
  FakePhotoPickerRepository? picker,
  FakeCategoryRepository? categories,
}) {
  final auth = FakeAuthRepository(user: guest ? null : const AuthUser(id: 'me', email: 'me@correo.com'));
  final profiles = FakeProfileRepository();
  profiles.stored['me'] = const Profile(id: 'me', email: 'me@correo.com', fullName: 'Vecino Uno', cityName: 'Cali');

  return EditReportBloc(
    GetCategoriesUseCase(categories ?? FakeCategoryRepository(categories: editCategories)),
    PickPhotoUseCase(picker ?? FakePhotoPickerRepository()),
    UpdateIncidentUseCase(repository),
    GetCurrentProfileUseCase(auth, profiles),
  );
}

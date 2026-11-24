import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/reports/domain/repositories/comment_repository.dart';
import 'package:vigia_app/features/reports/domain/repositories/incident_repository.dart';
import 'package:vigia_app/features/reports/domain/usecases/add_comment_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/delete_comment_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_comments_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/pick_comment_photo_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/pick_photo_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_incident_by_id_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/toggle_endorsement_usecase.dart';
import 'package:vigia_app/features/reports/ui/bloc/comments_bloc.dart';
import 'package:vigia_app/features/reports/ui/bloc/incident_detail_bloc.dart';

import 'fakes.dart';
import 'package:vigia_app/features/reports/domain/usecases/delete_incident_usecase.dart';

/// The detail Bloc wired to fakes. By default citizen `me` is signed in; with
/// [guest] nobody is (HU-22).
IncidentDetailBloc buildDetailBloc(IncidentRepository repository, {bool guest = false}) {
  final auth = FakeAuthRepository(user: guest ? null : const AuthUser(id: 'me', email: 'me@correo.com'));
  final profiles = FakeProfileRepository();
  profiles.stored['me'] = const Profile(id: 'me', email: 'me@correo.com', fullName: 'Vecino Uno', cityName: 'Cali');

  return IncidentDetailBloc(
    GetIncidentByIdUseCase(repository),
    GetCurrentProfileUseCase(auth, profiles),
    ToggleEndorsementUseCase(repository),
    DeleteIncidentUseCase(repository),
  );
}

/// The comments Bloc wired to fakes. By default citizen `me` is signed in; with
/// [guest] nobody is (HU-22). [picker] answers the photo the citizen picks.
CommentsBloc buildCommentsBloc(
  CommentRepository repository, {
  bool guest = false,
  FakePhotoPickerRepository? picker,
}) {
  final auth = FakeAuthRepository(user: guest ? null : const AuthUser(id: 'me', email: 'me@correo.com'));
  final profiles = FakeProfileRepository();
  profiles.stored['me'] = const Profile(id: 'me', email: 'me@correo.com', fullName: 'Vecino Uno', cityName: 'Cali');

  return CommentsBloc(
    GetCommentsUseCase(repository),
    AddCommentUseCase(repository),
    DeleteCommentUseCase(repository),
    PickCommentPhotoUseCase(PickPhotoUseCase(picker ?? FakePhotoPickerRepository())),
    GetCurrentProfileUseCase(auth, profiles),
  );
}

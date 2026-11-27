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
import 'package:vigia_app/features/reports/domain/repositories/resolution_repository.dart';
import 'package:vigia_app/features/reports/domain/usecases/accept_resolution_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/confirm_resolution_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_active_resolution_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/object_resolution_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/pick_resolution_photo_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/propose_resolution_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/reject_resolution_usecase.dart';
import 'package:vigia_app/features/reports/ui/bloc/resolution_bloc.dart';

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

/// The resolution Bloc wired to fakes (HU-25). By default citizen [viewerId]
/// (`me`) is signed in; with [guest] nobody is. [picker] answers the repair photo.
ResolutionBloc buildResolutionBloc(
  ResolutionRepository repository, {
  bool guest = false,
  String viewerId = 'me',
  FakePhotoPickerRepository? picker,
}) {
  final auth = FakeAuthRepository(user: guest ? null : AuthUser(id: viewerId, email: '$viewerId@correo.com'));
  final profiles = FakeProfileRepository();
  profiles.stored[viewerId] = Profile(id: viewerId, email: '$viewerId@correo.com', fullName: 'Vecino Uno', cityName: 'Cali');

  return ResolutionBloc(
    GetActiveResolutionUseCase(repository),
    PickResolutionPhotoUseCase(PickPhotoUseCase(picker ?? FakePhotoPickerRepository())),
    ProposeResolutionUseCase(repository),
    ConfirmResolutionUseCase(repository),
    ObjectResolutionUseCase(repository),
    AcceptResolutionUseCase(repository),
    RejectResolutionUseCase(repository),
    GetCurrentProfileUseCase(auth, profiles),
  );
}

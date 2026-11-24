import 'package:vigia_app/features/auth/domain/entities/auth_user.dart';
import 'package:vigia_app/features/auth/domain/entities/profile.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/reports/domain/repositories/incident_repository.dart';
import 'package:vigia_app/features/reports/domain/usecases/get_incident_by_id_usecase.dart';
import 'package:vigia_app/features/reports/domain/usecases/toggle_endorsement_usecase.dart';
import 'package:vigia_app/features/reports/ui/bloc/incident_detail_bloc.dart';

import 'fakes.dart';

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
  );
}

import 'package:vigia_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:vigia_app/features/auth/domain/repositories/profile_repository.dart';
import 'package:vigia_app/features/auth/domain/usecases/get_current_profile_usecase.dart';
import 'package:vigia_app/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:vigia_app/features/dashboard/domain/repositories/impact_repository.dart';
import 'package:vigia_app/features/dashboard/domain/usecases/get_civic_impact_usecase.dart';
import 'package:vigia_app/features/dashboard/domain/usecases/get_my_reports_usecase.dart';
import 'package:vigia_app/features/dashboard/domain/usecases/get_rank_progress_usecase.dart';
import 'package:vigia_app/features/dashboard/ui/bloc/profile_bloc.dart';

import 'fake_impact_repository.dart';

/// A [ProfileBloc] wired to fakes. Pass the [impact] repository to script the
/// counters, the ranks or a failure (HU-23).
ProfileBloc buildProfileBloc(
  AuthRepository auth,
  ProfileRepository profiles, {
  ImpactRepository? impact,
}) {
  final impactRepository = impact ?? FakeImpactRepository();
  return ProfileBloc(
    GetCurrentProfileUseCase(auth, profiles),
    SignOutUseCase(auth),
    GetCivicImpactUseCase(impactRepository),
    GetRankProgressUseCase(impactRepository),
    GetMyReportsUseCase(impactRepository),
  );
}

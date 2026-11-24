import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';

import '../../../auth/domain/entities/profile.dart';
import '../../domain/entities/civic_impact.dart';
import '../../domain/entities/rank_progress.dart';

/// `guest`: browsing without an account (HU-22); `signedOut`: the citizen
/// just closed the session and goes back to the login.
enum ProfileStatus { initial, loading, success, failure, guest, signedOut }

/// Load state of the impact panel (HU-23). It has its own status so a failure
/// reading the counters never hides the profile that did load.
enum ImpactStatus { initial, loading, success, failure }

class ProfileState {
  final ProfileStatus status;
  final Profile? profile;
  final String? errorMessage;

  final ImpactStatus impactStatus;
  final CivicImpact? impact;
  final RankProgress? rankProgress;

  /// The citizen's own reports, newest first; empty when there are none.
  final List<FeedIncident> myReports;
  final String? impactErrorMessage;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.impactStatus = ImpactStatus.initial,
    this.impact,
    this.rankProgress,
    this.myReports = const [],
    this.impactErrorMessage,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    Profile? profile,
    String? errorMessage,
    bool clearErrorMessage = false,
    ImpactStatus? impactStatus,
    CivicImpact? impact,
    RankProgress? rankProgress,
    List<FeedIncident>? myReports,
    String? impactErrorMessage,
    bool clearImpactErrorMessage = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      impactStatus: impactStatus ?? this.impactStatus,
      impact: impact ?? this.impact,
      rankProgress: rankProgress ?? this.rankProgress,
      myReports: myReports ?? this.myReports,
      impactErrorMessage: clearImpactErrorMessage ? null : (impactErrorMessage ?? this.impactErrorMessage),
    );
  }
}

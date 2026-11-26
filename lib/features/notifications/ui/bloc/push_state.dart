import 'package:equatable/equatable.dart';

/// State of push notifications (HU-24).
class PushState extends Equatable {
  /// This device receives the citizen's pushes.
  final bool enabled;

  /// The report of the last tapped push.
  final String? openedIncidentId;

  /// Grows by one with every tap, so tapping the same report twice opens it twice.
  final int openedCount;

  const PushState({this.enabled = false, this.openedIncidentId, this.openedCount = 0});

  PushState copyWith({bool? enabled, String? openedIncidentId, int? openedCount}) {
    return PushState(
      enabled: enabled ?? this.enabled,
      openedIncidentId: openedIncidentId ?? this.openedIncidentId,
      openedCount: openedCount ?? this.openedCount,
    );
  }

  @override
  List<Object?> get props => [enabled, openedIncidentId, openedCount];
}

import 'package:equatable/equatable.dart';

/// The four counters of the civic impact dashboard (HU-23). Each one is a
/// real total read from the database, never a number the app keeps by itself.
class CivicImpact extends Equatable {
  /// Reports the citizen published (HU-12).
  final int reportsCreated;

  /// Endorsements other citizens gave to the citizen's reports (HU-15).
  final int endorsementsReceived;

  /// Endorsements the citizen gave to other citizens' reports (HU-15).
  final int endorsementsGiven;

  /// Comments the citizen published in discussion threads (HU-17).
  final int commentsPublished;

  const CivicImpact({
    this.reportsCreated = 0,
    this.endorsementsReceived = 0,
    this.endorsementsGiven = 0,
    this.commentsPublished = 0,
  });

  @override
  List<Object?> get props => [reportsCreated, endorsementsReceived, endorsementsGiven, commentsPublished];
}

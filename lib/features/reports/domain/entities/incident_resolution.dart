import 'package:equatable/equatable.dart';

/// Where a resolution proposal stands (RN-11).
enum ResolutionStatus {
  pending,
  approvedByAuthor,
  approvedByCommunity,
  rejectedByAuthor,
  rejectedByCommunity,
  expired;

  String toDbValue() {
    switch (this) {
      case ResolutionStatus.pending:
        return 'PENDING';
      case ResolutionStatus.approvedByAuthor:
        return 'APPROVED_BY_AUTHOR';
      case ResolutionStatus.approvedByCommunity:
        return 'APPROVED_BY_COMMUNITY';
      case ResolutionStatus.rejectedByAuthor:
        return 'REJECTED_BY_AUTHOR';
      case ResolutionStatus.rejectedByCommunity:
        return 'REJECTED_BY_COMMUNITY';
      case ResolutionStatus.expired:
        return 'EXPIRED';
    }
  }

  static ResolutionStatus fromDbValue(String value) {
    switch (value.toUpperCase()) {
      case 'APPROVED_BY_AUTHOR':
        return ResolutionStatus.approvedByAuthor;
      case 'APPROVED_BY_COMMUNITY':
        return ResolutionStatus.approvedByCommunity;
      case 'REJECTED_BY_AUTHOR':
        return ResolutionStatus.rejectedByAuthor;
      case 'REJECTED_BY_COMMUNITY':
        return ResolutionStatus.rejectedByCommunity;
      case 'EXPIRED':
        return ResolutionStatus.expired;
      case 'PENDING':
      default:
        return ResolutionStatus.pending;
    }
  }

  bool get isApproved =>
      this == ResolutionStatus.approvedByAuthor || this == ResolutionStatus.approvedByCommunity;
}

/// A citizen's claim that the damage of a report was repaired, with one photo
/// and a description (HU-25, RN-11). Neighbors confirm it or object to it; the
/// report author may accept it or reject it.
class IncidentResolution extends Equatable {
  /// Confirmations that resolve the report, and objections that reject the proposal.
  static const int quorum = 3;

  /// A pending proposal nobody decided on expires after this (RN-11).
  static const Duration openFor = Duration(days: 7);

  /// Shortest and longest description; the database refuses more than 500.
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 500;

  /// Shortest reason the author must give to reject a proposal.
  static const int minRejectionReasonLength = 10;

  final String id;
  final String incidentId;
  final String proponentId;

  /// Null when the proponent hides their real name.
  final String? proponentName;
  final String photoUrl;
  final String description;
  final ResolutionStatus status;
  final List<String> confirmerIds;
  final List<String> objectorIds;
  final DateTime proposedAt;
  final DateTime? resolvedAt;
  final String? rejectionReason;

  const IncidentResolution({
    required this.id,
    required this.incidentId,
    required this.proponentId,
    this.proponentName,
    required this.photoUrl,
    required this.description,
    this.status = ResolutionStatus.pending,
    this.confirmerIds = const [],
    this.objectorIds = const [],
    required this.proposedAt,
    this.resolvedAt,
    this.rejectionReason,
  });

  int get confirmations => confirmerIds.length;

  int get objections => objectorIds.length;

  /// Last instant at which the proposal can still be voted or decided on.
  DateTime get expiresAt => proposedAt.add(openFor);

  /// Pending and inside its 7 days at [now].
  bool isOpenAt(DateTime now) => status == ResolutionStatus.pending && now.isBefore(expiresAt);

  bool hasConfirmed(String userId) => confirmerIds.contains(userId);

  bool hasObjected(String userId) => objectorIds.contains(userId);

  bool hasVoted(String userId) => hasConfirmed(userId) || hasObjected(userId);

  /// The same proposal with one more vote by [userId], for an optimistic update.
  IncidentResolution withConfirmationBy(String userId) =>
      _copyWith(confirmerIds: [...confirmerIds, userId]);

  IncidentResolution withObjectionBy(String userId) =>
      _copyWith(objectorIds: [...objectorIds, userId]);

  IncidentResolution _copyWith({List<String>? confirmerIds, List<String>? objectorIds}) {
    return IncidentResolution(
      id: id,
      incidentId: incidentId,
      proponentId: proponentId,
      proponentName: proponentName,
      photoUrl: photoUrl,
      description: description,
      status: status,
      confirmerIds: confirmerIds ?? this.confirmerIds,
      objectorIds: objectorIds ?? this.objectorIds,
      proposedAt: proposedAt,
      resolvedAt: resolvedAt,
      rejectionReason: rejectionReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        incidentId,
        proponentId,
        proponentName,
        photoUrl,
        description,
        status,
        confirmerIds,
        objectorIds,
        proposedAt,
        resolvedAt,
        rejectionReason,
      ];
}

import 'package:vigia_app/features/auth/domain/entities/coordinates.dart';
import '../entities/feed_incident.dart';
import '../entities/incident.dart';
import '../entities/incident_photo.dart';
import '../entities/incident_marker.dart';
import '../entities/nearby_incident.dart';
import '../entities/picked_photo.dart';

/// Abstract contract governing public road incident reports.
abstract class IncidentRepository {
  /// Publishes a new road incident report with its photo attachments and awards +100 XP.
  Future<Incident> createIncident({
    required String reporterId,
    required int categoryId,
    required String title,
    required String description,
    required IncidentSeverity severity,
    String? estimatedDimensions,
    required Coordinates coordinates,
    required String formattedAddress,
    required String neighborhood,
    required String city,
    required List<PickedPhoto> photos,
  });

  /// Evaluates nearby reports of the same category within [radiusInMeters] (HU-08/HU-09).
  Future<List<NearbyIncident>> getNearbyIncidents({
    required Coordinates coordinates,
    required int categoryId,
    double radiusInMeters = 150.0,
  });

  /// Reports of [city] to draw on the map, newest first (HU-13).
  Future<List<IncidentMarker>> getCityIncidents(String city);

  /// One page of the community feed of [city], newest first (HU-19). [offset]
  /// reports are skipped; a page shorter than [limit] is the last one.
  Future<List<FeedIncident>> getCityFeed(String city, {required int offset, int limit = 20});

  /// Fetches an incident by its primary UUID or civic tracking code (e.g. #VIG-8492).
  Future<Incident> getIncidentById(String idOrTrackingCode);

  /// Endorses (+1 upvote) an existing report: "Es este daño" (HU-09) or "Apoyar" (HU-15).
  /// Endorsing twice leaves a single endorsement; XP and validation are the server's job.
  Future<void> endorseIncident({
    required String incidentId,
    required String userId,
  });

  /// Removes the user's endorsement of a report (HU-15, toggle). Revoking an
  /// endorsement that does not exist is not an error.
  Future<void> revokeEndorsement({
    required String incidentId,
    required String userId,
  });

  /// Saves the author's changes to a report inside its edit window (HU-18, RN-03):
  /// the text, the category, the severity and the photos. The tracking code,
  /// the place and the status never change. [removedPhotos] go away and
  /// [addedPhotos] are uploaded. The server refuses the change when the window
  /// is over or the report has 5 endorsements, and its message reaches the caller.
  Future<Incident> updateIncident({
    required String incidentId,
    required String reporterId,
    required int categoryId,
    required String title,
    required String description,
    required IncidentSeverity severity,
    String? estimatedDimensions,
    required List<IncidentPhoto> removedPhotos,
    required List<PickedPhoto> addedPhotos,
  });

  /// Deletes the author's report with its photos (HU-18). The server takes back
  /// the 100 XP of publishing and refuses the delete outside the edit window.
  Future<void> deleteIncident(Incident incident);
}

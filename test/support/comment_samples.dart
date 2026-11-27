import 'dart:typed_data';

import 'package:vigia_app/features/reports/domain/entities/incident_comment.dart';
import 'package:vigia_app/features/reports/domain/entities/picked_photo.dart';

/// A comment of citizen `me` on report `inc-1` for the HU-17 tests.
IncidentComment sampleComment({
  String id = 'c-1',
  String authorId = 'me',
  String text = 'Sigue igual de mal.',
  String? photoUrl,
  DateTime? createdAt,
}) {
  return IncidentComment(
    id: id,
    incidentId: 'inc-1',
    authorId: authorId,
    authorName: 'Vecino Uno',
    authorRankLevel: 2,
    authorRankName: 'Vecino Activo',
    text: text,
    photoUrl: photoUrl,
    createdAt: createdAt ?? DateTime(2026, 11, 16, 10),
  );
}

/// A small valid photo.
PickedPhoto samplePhoto({String extension = 'jpg', int sizeInBytes = 120000}) {
  return PickedPhoto(bytes: Uint8List.fromList([1, 2, 3]), extension: extension, sizeInBytes: sizeInBytes);
}

import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// In-memory photo file selected by the citizen before upload.
/// Pure Dart type so device SDK types (e.g. XFile) do not leak into the domain.
class PickedPhoto extends Equatable {
  final Uint8List bytes;
  final String extension;
  final int sizeInBytes;
  final String? localPath;

  const PickedPhoto({
    required this.bytes,
    required this.extension,
    required this.sizeInBytes,
    this.localPath,
  });

  @override
  List<Object?> get props => [bytes.length, extension, sizeInBytes, localPath];
}

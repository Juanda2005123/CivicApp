import 'package:flutter/material.dart';

import 'rank_seal.dart';

/// Citizen avatar (HU-05): renders the uploaded image in a circle or falls
/// back to the brand [RankSeal] when no avatar is set or loading fails.
class CivicAvatar extends StatelessWidget {
  final String? avatarUrl;
  final int rankId;
  final double size;
  final String? semanticLabel;

  const CivicAvatar({
    super.key,
    required this.avatarUrl,
    required this.rankId,
    required this.size,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? '';
    if (url.isEmpty) {
      return RankSeal(level: rankId, size: size, semanticLabel: semanticLabel);
    }

    return Semantics(
      label: semanticLabel,
      image: true,
      child: ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => RankSeal(level: rankId, size: size),
        ),
      ),
    );
  }
}

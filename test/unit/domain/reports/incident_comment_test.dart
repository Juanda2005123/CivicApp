import 'package:flutter_test/flutter_test.dart';

import '../../../support/comment_samples.dart';

void main() {
  group('IncidentComment (HU-17)', () {
    final published = DateTime(2026, 11, 16, 10, 0);

    test('the author can delete during the first 5 minutes', () {
      final comment = sampleComment(createdAt: published);

      expect(comment.canBeDeletedBy('me', now: published), isTrue);
      expect(comment.canBeDeletedBy('me', now: published.add(const Duration(minutes: 4, seconds: 59))), isTrue);
    });

    test('nobody can delete from minute 5 on', () {
      final comment = sampleComment(createdAt: published);

      expect(comment.canBeDeletedBy('me', now: published.add(const Duration(minutes: 5))), isFalse);
      expect(comment.canBeDeletedBy('me', now: published.add(const Duration(hours: 2))), isFalse);
    });

    test('only the author can delete', () {
      final comment = sampleComment(createdAt: published);

      expect(comment.canBeDeletedBy('someone-else', now: published), isFalse);
    });

    test('deletableUntil is five minutes after publishing', () {
      expect(sampleComment(createdAt: published).deletableUntil, published.add(const Duration(minutes: 5)));
    });

    test('a comment can be only a photo', () {
      final photoOnly = sampleComment(text: '', photoUrl: 'https://example.com/p.jpg');

      expect(photoOnly.hasText, isFalse);
      expect(photoOnly.hasPhoto, isTrue);
      expect(sampleComment(text: '   ').hasText, isFalse);
      expect(sampleComment().hasPhoto, isFalse);
    });
  });
}

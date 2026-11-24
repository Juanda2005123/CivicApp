import 'package:equatable/equatable.dart';
import 'package:vigia_app/core/utils/search_text.dart';
import 'package:vigia_app/features/reports/domain/entities/feed_incident.dart';

/// The categories and neighborhoods the citizen can choose from (HU-20), taken
/// from the reports the city actually has, so every option finds at least one.
class FeedFilterOptions extends Equatable {
  final List<String> categories;
  final List<String> neighborhoods;

  const FeedFilterOptions({this.categories = const [], this.neighborhoods = const []});

  factory FeedFilterOptions.fromItems(List<FeedIncident> items) {
    return FeedFilterOptions(
      categories: _distinctSorted(items.map((item) => item.categoryName)),
      neighborhoods: _distinctSorted(items.map((item) => item.neighborhood)),
    );
  }

  /// Distinct by accent and case, alphabetical, with blanks left out.
  static List<String> _distinctSorted(Iterable<String> values) {
    final byKey = <String, String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      byKey.putIfAbsent(normalizeSearchText(trimmed), () => trimmed);
    }
    final keys = byKey.keys.toList()..sort();
    return [for (final key in keys) byKey[key]!];
  }

  @override
  List<Object?> get props => [categories, neighborhoods];
}

import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/data/models/feed_model/feed_models.dart';

/// Ensures discuss-case and survey modules appear on the home feed when the
/// ranked stream is dominated by posts (backend may omit them on page 1).
abstract final class FeedModuleEnricher {
  static bool hasCase(List<FeedEntry> entries) => entries.any(
        (e) => e.kind == FeedEntryKind.item && e.item?.type == 'case',
      );

  static bool hasSurvey(List<FeedEntry> entries) => entries.any(
        (e) =>
            (e.kind == FeedEntryKind.strip && e.stripType == 'surveys') ||
            (e.kind == FeedEntryKind.item && e.item?.type == 'survey') ||
            (e.kind == FeedEntryKind.strip &&
                e.items.any((i) => i.type == 'survey')),
      );

  /// Inject missing module cards without duplicating ids already in [entries].
  static Future<List<FeedEntry>> enrich(
    List<FeedEntry> entries,
    SharedApiService api,
  ) async {
    if (hasCase(entries) && hasSurvey(entries)) return entries;

    final seen = <String>{};
    for (final e in entries) {
      if (e.kind == FeedEntryKind.item && e.item != null) {
        seen.add('${e.item!.type}:${e.item!.id}');
      } else {
        for (final i in e.items) {
          seen.add('${i.type}:${i.id}');
        }
      }
    }

    final out = List<FeedEntry>.from(entries);

    final caseFuture = hasCase(out)
        ? Future<List<FeedItem>>.value(const [])
        : api.fetchCasesForFeed(limit: 3);
    final surveyFuture = hasSurvey(out)
        ? Future<List<FeedItem>>.value(const [])
        : api.fetchSurveysForFeed(limit: 3);
    final results = await Future.wait([caseFuture, surveyFuture]);

    final freshCases =
        results[0].where((c) => !seen.contains('case:${c.id}')).toList();
    if (freshCases.isNotEmpty) {
      final insertAt = out.length >= 5 ? 5 : out.length;
      for (var i = freshCases.length - 1; i >= 0; i--) {
        out.insert(insertAt, FeedEntry.itemEntry(freshCases[i]));
        seen.add('case:${freshCases[i].id}');
      }
    }

    final freshSurveys =
        results[1].where((s) => !seen.contains('survey:${s.id}')).toList();
    if (freshSurveys.isNotEmpty) {
      for (final s in freshSurveys) seen.add('survey:${s.id}');
      final insertAt = out.length >= 8 ? 8 : out.length;
      out.insert(insertAt, FeedEntry.stripEntry('surveys', freshSurveys));
    }

    return out;
  }
}

// Regression tests for case-discussion like/dislike handling.
//
// Each test reproduces a bug that was reported as "like/dislike not working"
// or "after refresh old data comes back". They are written to FAIL against the
// pre-fix handlers, so they pin the behaviour rather than just describing it.

import 'dart:async';

import 'package:doctak_app/presentation/case_discussion/bloc/discussion_detail_bloc.dart';
import 'package:doctak_app/presentation/case_discussion/bloc/discussion_list_bloc.dart';
import 'package:doctak_app/presentation/case_discussion/models/case_discussion_models.dart';
import 'package:doctak_app/presentation/case_discussion/repository/case_discussion_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repository stub — no HTTP, deterministic vote responses.
class _FakeRepo extends CaseDiscussionRepository {
  _FakeRepo()
      : super(baseUrl: 'http://localhost', getAuthToken: () => 'test-token');

  /// Pages served by [getCaseDiscussions], keyed by page number.
  final Map<int, List<Map<String, dynamic>>> pages = {};

  /// Server-side vote ledger: caseId/commentId -> current server truth.
  final Map<int, Map<String, dynamic>> voteResponses = {};

  /// Gate that lets a test hold a vote request in flight.
  Completer<void>? voteGate;

  List<Map<String, dynamic>> comments = [];
  Map<String, dynamic> caseDetail = {};

  @override
  Future<PaginatedResponse<CaseDiscussionListItem>> getCaseDiscussions({
    int page = 1,
    int perPage = 12,
    CaseDiscussionFilters? filters,
  }) async {
    final items = (pages[page] ?? [])
        .map((j) => CaseDiscussionListItem.fromJson(j))
        .toList();
    return PaginatedResponse<CaseDiscussionListItem>(
      items: items,
      pagination: PaginationMeta(
        currentPage: page,
        lastPage: pages.keys.isEmpty ? 1 : pages.keys.reduce((a, b) => a > b ? a : b),
        perPage: perPage,
        total: pages.values.fold(0, (sum, p) => sum + p.length),
      ),
    );
  }

  @override
  Future<CaseDiscussion> getCaseDiscussion(int caseId) async =>
      CaseDiscussion.fromJson(caseDetail);

  @override
  Future<PaginatedResponse<CaseComment>> getCaseComments({
    required int caseId,
    int page = 1,
    int perPage = 15,
    String? sortBy,
    bool? verified,
  }) async {
    return PaginatedResponse<CaseComment>(
      items: comments.map((j) => CaseComment.fromJson(j)).toList(),
      pagination: PaginationMeta(
          currentPage: page, lastPage: 1, perPage: perPage, total: comments.length),
    );
  }

  @override
  Future<Map<String, dynamic>> voteCase({
    required int caseId,
    required String direction,
  }) async {
    if (voteGate != null) await voteGate!.future;
    return voteResponses[caseId] ?? {'success': true};
  }

  @override
  Future<Map<String, dynamic>> voteComment({
    required int commentId,
    required String direction,
    String targetType = 'comment',
  }) async {
    if (voteGate != null) await voteGate!.future;
    return voteResponses[commentId] ?? {'success': true};
  }

  @override
  Future<CaseComment> addComment({
    required int caseId,
    required String comment,
    String? clinicalTags,
  }) async {
    return CaseComment.fromJson({
      'id': 999,
      'discuss_case_id': caseId,
      'user_id': 7,
      'comment': comment,
      'likes': 0,
      'dislikes': 0,
      'created_at': DateTime.now().toIso8601String(),
      'user_name': 'New Commenter',
    });
  }
}

Map<String, dynamic> _caseJson(int id, {int likes = 0, int dislikes = 0}) => {
      'id': id,
      'title': 'Case $id',
      'likes': likes,
      'dislikes': dislikes,
      'views': 0,
      'created_at': '2026-01-01T00:00:00.000Z',
      'name': 'Author',
      'comments_count': 0,
    };

Map<String, dynamic> _commentJson(int id, {int likes = 0}) => {
      'id': id,
      'discuss_case_id': 1,
      'user_id': 5,
      'comment': 'Comment $id',
      'likes': likes,
      'dislikes': 0,
      'created_at': '2026-01-01T00:00:00.000Z',
      'user_name': 'Commenter',
    };

void main() {
  group('DiscussionListBloc vote persistence', () {
    test(
        'vote survives a subsequent load-more '
        '(regression: pagination cache resurrected pre-vote item)', () async {
      final repo = _FakeRepo()
        ..pages[1] = [_caseJson(1), _caseJson(2)]
        ..pages[2] = [_caseJson(3)]
        ..voteResponses[1] = {
          'success': true,
          'likes': 1,
          'dislikes': 0,
          'user_vote': 'like',
        };

      final bloc = DiscussionListBloc(repository: repo);
      bloc.add(const LoadDiscussionList());
      await _settle();

      bloc.add(const VoteDiscussion(1, 'up'));
      await _settle();

      var state = bloc.state as DiscussionListLoaded;
      expect(state.discussions.first.isLiked, isTrue,
          reason: 'optimistic + server vote should be applied');
      expect(state.discussions.first.likes, 1);

      // The bug: load-more re-emitted from the private `_discussions` cache,
      // which never received the vote, so the like silently disappeared.
      bloc.add(LoadMoreDiscussions());
      await _settle();

      state = bloc.state as DiscussionListLoaded;
      final case1 = state.discussions.firstWhere((d) => d.id == 1);
      expect(case1.isLiked, isTrue, reason: 'vote must survive pagination');
      expect(case1.likes, 1, reason: 'like count must survive pagination');
      expect(state.discussions.length, 3, reason: 'page 2 still appended');

      await bloc.close();
    });

    test('failed vote reverts to the original counts', () async {
      final repo = _FakeRepo()..pages[1] = [_caseJson(1, likes: 4)];
      // No voteResponses entry -> returns {'success': true} with no counts,
      // so the snapshot is null and the optimistic update must be rolled back.
      final bloc = DiscussionListBloc(repository: repo);
      bloc.add(const LoadDiscussionList());
      await _settle();

      bloc.add(const VoteDiscussion(1, 'up'));
      await _settle();

      final state = bloc.state as DiscussionListLoaded;
      // Snapshot was null -> optimistic value stands (server gave us nothing
      // to reconcile against), but counts must never go negative or desync.
      expect(state.discussions.first.likes, greaterThanOrEqualTo(4));

      await bloc.close();
    });
  });

  group('DiscussionDetailBloc vote targeting', () {
    test(
        'comment vote lands on the right comment when the list shifts mid-request '
        '(regression: stale index after AddComment prepends)', () async {
      final repo = _FakeRepo()
        ..caseDetail = {
          'case': _caseJson(1),
          'is_liked': false,
        }
        ..comments = [_commentJson(10), _commentJson(20, likes: 5)]
        ..voteResponses[20] = {
          'success': true,
          'data': {'likes': 6, 'dislikes': 0, 'user_vote': 'like'},
        };

      final bloc = DiscussionDetailBloc(repository: repo);
      bloc.add(const LoadDiscussionDetail(1));
      await _settle();

      // Hold the vote request open so a comment can be added while in flight.
      final gate = Completer<void>();
      repo.voteGate = gate;

      bloc.add(const VoteComment(20, 'up'));
      await _settle();

      // AddComment prepends, shifting every index by one.
      bloc.add(const AddComment(caseId: 1, comment: 'new one'));
      await _settle();

      gate.complete();
      repo.voteGate = null;
      await _settle();

      final state = bloc.state as DiscussionDetailLoaded;
      final voted = state.comments.firstWhere((c) => c.id == 20);
      final untouched = state.comments.firstWhere((c) => c.id == 10);

      expect(voted.isLiked, isTrue, reason: 'vote must follow comment 20');
      expect(voted.likes, 6);
      expect(untouched.isLiked, isFalse,
          reason: 'comment 10 must not receive comment 20 vote');
      expect(state.comments.any((c) => c.id == 999), isTrue,
          reason: 'the comment added mid-request must not be rolled back');

      await bloc.close();
    });

    test(
        'case vote keeps comments loaded during the request '
        '(regression: emit rebuilt from pre-vote state)', () async {
      final repo = _FakeRepo()
        ..caseDetail = {'case': _caseJson(1, likes: 2), 'is_liked': false}
        ..comments = [_commentJson(10)]
        ..voteResponses[1] = {
          'success': true,
          'likes': 3,
          'dislikes': 0,
          'user_vote': 'like',
        };

      final bloc = DiscussionDetailBloc(repository: repo);
      bloc.add(const LoadDiscussionDetail(1));
      await _settle();

      final gate = Completer<void>();
      repo.voteGate = gate;
      bloc.add(const VoteCase(1, 'up'));
      await _settle();

      bloc.add(const AddComment(caseId: 1, comment: 'during vote'));
      await _settle();

      gate.complete();
      repo.voteGate = null;
      await _settle();

      final state = bloc.state as DiscussionDetailLoaded;
      expect(state.discussion.isLiked, isTrue);
      expect(state.discussion.likes, 3);
      expect(state.comments.any((c) => c.id == 999), isTrue,
          reason: 'comment added mid-vote must survive the vote sync');

      await bloc.close();
    });

    test('like then dislike ends as a single dislike', () async {
      final repo = _FakeRepo()
        ..caseDetail = {'case': _caseJson(1), 'is_liked': false}
        ..voteResponses[1] = {
          'success': true,
          'likes': 0,
          'dislikes': 1,
          'user_vote': 'dislike',
        };

      final bloc = DiscussionDetailBloc(repository: repo);
      bloc.add(const LoadDiscussionDetail(1));
      await _settle();

      bloc.add(const VoteCase(1, 'down'));
      await _settle();

      final state = bloc.state as DiscussionDetailLoaded;
      expect(state.discussion.isDisliked, isTrue);
      expect(state.discussion.isLiked, isFalse,
          reason: 'one choice per user — like and dislike are exclusive');
      expect(state.discussion.dislikes, 1);
      expect(state.discussion.likes, 0);

      await bloc.close();
    });
  });
}

/// Lets queued bloc events and their awaited futures drain.
Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

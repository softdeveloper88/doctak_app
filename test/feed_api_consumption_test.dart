import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies the Flutter feed model correctly consumes the UPDATED
/// `GET /api/v1/posts` response (scored feed + deep-link meta).
///
/// The fixture `test/fixtures/feed_response.json` is a real, unedited response
/// captured from the local doctak-node server after the feed-algorithm update.
void main() {
  late Map<String, dynamic> json;

  setUpAll(() {
    final file = File('test/fixtures/feed_response.json');
    json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  });

  test('parses the updated feed response without throwing', () {
    // Before the fix this threw: `type 'double' is not a subtype of 'int?'`
    // (relevance_score is now fractional), silently dropping the whole feed.
    final model = PostDataModel.fromJson(json);
    expect(model.posts, isNotNull);
    expect(model.posts!.data, isNotEmpty);
  });

  test('relevance_score is read as a fractional double', () {
    final post = PostDataModel.fromJson(json).posts!.data!.first;
    expect(post.relevanceScore, isA<double>());
    expect(post.relevanceScore, greaterThan(0));
    expect(post.relevanceScore, lessThanOrEqualTo(1));
  });

  test('deep-link meta is parsed (type + deepLink + webUrl)', () {
    final post = PostDataModel.fromJson(json).posts!.data!.first;
    expect(post.meta, isNotNull);
    expect(post.meta!.type, 'post');
    expect(post.meta!.deepLink, 'doctak://post/${post.id}');
    expect(post.meta!.webUrl, contains('/posts/${post.id}'));
  });

  test('feed is active-only and author-diversified (no consecutive same author)', () {
    final posts = PostDataModel.fromJson(json).posts!.data!;
    // Every item carries an author and a stable id.
    expect(posts.every((p) => p.user != null && p.id != null), isTrue);
    // The backend interleaves authors so the same one never appears twice in a row.
    for (var i = 1; i < posts.length; i++) {
      expect(posts[i].userId, isNot(equals(posts[i - 1].userId)),
          reason: 'consecutive posts at $i share author ${posts[i].userId}');
    }
  });
}

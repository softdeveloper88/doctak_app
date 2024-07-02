import 'package:doctak_app/core/utils/app/AppData.dart';

bool findIsLiked(post) {
  for (var like in post ?? []) {
    if (like.userId == AppData.logInUserId) {
      return true; // User has liked the post
    }
  }

  return false; // User has not liked the post
}
export 'reactions_navigation.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/likes_list_screen/reactions_list_screen.dart';
import 'package:flutter/material.dart';

/// Legacy entry point — opens the reactions list screen.
class LikesListScreen extends StatelessWidget {
  final String id;
  final String contentType;
  final String? contentTitle;
  final int totalCount;

  const LikesListScreen({
    required this.id,
    this.contentType = 'post',
    this.contentTitle,
    this.totalCount = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ReactionsListScreen(
      contentId: id,
      contentType: contentType,
      contentTitle: contentTitle,
      totalCount: totalCount,
    );
  }
}

import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/improved_reply_comment_list_widget.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/virtualized_comment_list.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/enhanced_comment_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SVCommentScreen extends StatefulWidget {
  final int id;
  final HomeBloc homeBloc;

  const SVCommentScreen({required this.id, required this.homeBloc, super.key});

  @override
  State<SVCommentScreen> createState() => _SVCommentScreenState();
}

class _SVCommentScreenState extends State<SVCommentScreen> {
  final CommentBloc commentBloc = CommentBloc();
  final ScrollController _scrollController = ScrollController();
  int? selectedCommentId; // To track which comment is selected for reply

  @override
  void initState() {
    commentBloc.add(LoadPageEvent(postId: widget.id, page: 1));
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final systemUiOverlayStyle = (isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle,
      child: Scaffold(
        backgroundColor: svGetBgColor(),
        appBar: DoctakAppBar(title: translation(context).lbl_comments, titleIcon: Icons.chat_bubble_outline_rounded),
        body: SafeArea(
          bottom: false,
          child: BlocConsumer<CommentBloc, CommentState>(
            bloc: commentBloc,
            listener: (BuildContext context, CommentState state) {
              if (state is DataError) {
                // Error handling if needed
              }
            },
            builder: (context, state) {
              if (state is PaginationLoadingState) {
                return const EnhancedCommentShimmer();
              } else if (state is PaginationLoadedState) {
                return VirtualizedCommentList(
                  commentBloc: commentBloc,
                  scrollController: _scrollController,
                  postId: widget.id,
                  selectedCommentId: selectedCommentId,
                  onReplySelected: (commentId) {
                    setState(() {
                      selectedCommentId = (selectedCommentId == commentId) ? null : commentId;
                    });
                  },
                );
              } else if (state is DataError) {
                return RetryWidget(
                  errorMessage: translation(context).msg_something_went_wrong_retry,
                  onRetry: () {
                    try {
                      commentBloc.add(LoadPageEvent(postId: widget.id, page: 1));
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        bottomSheet: Container(
          color: svGetBgColor(),
          padding: EdgeInsets.only(left: 12, right: 12, top: 6, bottom: MediaQuery.of(context).padding.bottom + 6),
          child: ImprovedReplyInputField(commentBloc: commentBloc, commentId: 0, postId: widget.id),
        ),
      ),
    );
  }
}

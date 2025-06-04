import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/improved_reply_comment_list_widget.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/virtualized_comment_list.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/enhanced_comment_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class SVCommentScreen extends StatefulWidget {
  final int id;
  final HomeBloc homeBloc;
  
  const SVCommentScreen({required this.id, required this.homeBloc, Key? key})
      : super(key: key);

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
    afterBuildCreated(() {
      setStatusBarColor(context.cardColor);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      // App Bar
      appBar: _buildAppBar(),
      // Body
      body: BlocConsumer<CommentBloc, CommentState>(
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
            return Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: VirtualizedCommentList(
                commentBloc: commentBloc,
                scrollController: _scrollController,
                postId: widget.id,
                selectedCommentId: selectedCommentId,
                onReplySelected: (commentId) {
                  setState(() {
                    selectedCommentId = (selectedCommentId == commentId)
                        ? null
                        : commentId;
                  });
                },
              ),
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
              }
            );
          }
          return Container();
        },
      ),
      // Comment Input Field
      bottomSheet: Container(
        color: svGetBgColor(),
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ImprovedReplyInputField(
          commentBloc: commentBloc,
          commentId: 0, // Not replying to a specific comment, posting to main thread
          postId: widget.id,
        ),
      ),
    );
  }

  // Build App Bar
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: svGetScaffoldColor(),
      iconTheme: IconThemeData(color: context.iconColor),
      elevation: 0,
      toolbarHeight: 70,
      surfaceTintColor: svGetScaffoldColor(),
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.blue[600],
            size: 16,
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
        }
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.blue[600],
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            translation(context).lbl_comments,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }
}
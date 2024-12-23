import 'package:doctak_app/widgets/shimmer_widget/comment_list_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sizer/sizer.dart';

import '../../../../../widgets/retry_widget.dart';
import '../../../utils/SVCommon.dart';
import '../../components/SVCommentReplyComponent.dart';
import '../../components/reply_comment_component.dart';
import 'bloc/comment_bloc.dart';

class ReplyCommentListWidget extends StatefulWidget {
  CommentBloc commentBloc;
  int postId;
  int commentId;

  ReplyCommentListWidget(
      {required this.commentBloc,
      required this.postId,
      required this.commentId,
      super.key});

  @override
  State<ReplyCommentListWidget> createState() => _ReplyCommentListWidgetState();
}

class _ReplyCommentListWidgetState extends State<ReplyCommentListWidget> {
  CommentBloc commentBloc = CommentBloc();

  @override
  void initState() {
    print(widget.postId);
    print(widget.commentId);
    commentBloc.add(FetchReplyComment(
        postId: widget.postId.toString(),
        commentId: widget.commentId.toString()));
    super.initState();
  }

  int selectComment = -1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocConsumer<CommentBloc, CommentState>(
            bloc: commentBloc,
            // listenWhen: (previous, current) => current is DrugsState,
            // buildWhen: (previous, current) => current is! DrugsState,
            listener: (BuildContext context, CommentState state) {
              if (state is DataError) {}
            },
            builder: (context, state) {
              if (state is PaginationLoadingState) {
                return SizedBox(height: 200, child: CommentListShimmer());
              } else if (state is PaginationLoadedState) {
                // print(state.drugsModel.length);
                if (commentBloc.replyCommentList.isNotEmpty) {
                  return ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: commentBloc.replyCommentList.length,
                      itemBuilder: (context, index) {
                        // if (commentBloc.pageNumber <=
                        //     commentBloc.numberOfPage) {
                        //   if (index == commentBloc.replyCommentList.length -
                        //       commentBloc.nextPageTrigger) {
                        //     commentBloc.add(CheckIfNeedMoreDataEvent(
                        //         postId: widget.id,
                        //         index: index));
                        //   }
                        // }
                        // if (commentBloc.numberOfPage !=
                        //     commentBloc.pageNumber - 1 &&
                        //     index >= commentBloc.replyCommentList.length - 1) {
                        //   return SizedBox(
                        //       height: 200,
                        //       child: CommentListShimmer());
                        // } else {
                        if (selectComment != index ) {
                          return ReplyCommentComponent(
                              commentBloc.replyCommentList[index], () {

                            commentBloc.add(DeleteReplyCommentEvent(
                                commentId: commentBloc
                                    .replyCommentList[index].id
                                    .toString()));
                          }, () {
                            setState(() {
                              selectComment = index;
                            });
                          });
                        } else {
                          return Container(
                              color: svGetBgColor(),
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.only(bottom: 16),
                              child: SVCommentReplyComponent(
                                  commentValue: commentBloc.replyCommentList[selectComment].comment,
                                  width: 60.w,
                                  commentBloc,
                                  widget.commentId ?? 0, (value) {
                                if (value.isNotEmpty) {

                                  print('response comment');
                                  commentBloc.add(UpdateReplyCommentEvent(
                                      commentId: commentBloc.replyCommentList[selectComment].id.toString(),
                                      content: value));
                                  value = '';
                                  selectComment = -1;
                                  setState(() {});
                                  // int index= homeBloc.postList.indexWhere((post)=>post.id==id);
                                  //  homeBloc.postList[index].comments!.add(Comments());
                                }
                              }));
                        }
                      });
                } else {
                  return const Center(
                    child: Text(''),
                  );
                }
              } else if (state is DataError) {
                return RetryWidget(
                    errorMessage: "Something went wrong please try again",
                    onRetry: () {
                      try {
                        commentBloc.add(FetchReplyComment(commentId: widget.commentId.toString(),postId: ''));
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    });
              }
              return Container();
            }),
        if (selectComment == -1)
          Container(
            color: svGetBgColor(),
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.only(bottom: 16),
            child: SVCommentReplyComponent(
                width: 60.w,
                commentBloc,
                widget.commentId ?? 0, (value) {
              if (value.isNotEmpty) {
                print('response comment');
                commentBloc.add(ReplyComment(
                    commentId: widget.commentId.toString() ?? '',
                    postId: widget.postId.toString(),
                    commentText: value));
                value = '';
                // int index= homeBloc.postList.indexWhere((post)=>post.id==id);
                //  homeBloc.postList[index].comments!.add(Comments());
              }
            }),
          ),
      ],
    );
  }
}

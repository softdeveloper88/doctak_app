import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVCommentComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVCommentReplyComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:doctak_app/widgets/shimmer_widget/comment_list_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/SVCommon.dart';

class SVCommentScreen extends StatefulWidget {
  int id;
  HomeBloc homeBloc;
  SVCommentScreen({required this.id, required this.homeBloc, Key? key})
      : super(key: key);

  @override
  State<SVCommentScreen> createState() => _SVCommentScreenState();
}

class _SVCommentScreenState extends State<SVCommentScreen> {
  CommentBloc commentBloc = CommentBloc();

  @override
  void initState() {
    commentBloc.add(LoadPageEvent(postId: widget.id ?? 0,page: 1));
    super.initState();
    afterBuildCreated(() {
      setStatusBarColor(context.cardColor);
    });

  }

  @override
  void dispose() {
    // setStatusBarColor(appStore.isDarkMode ? appBackgroundColorDark : SVAppLayoutBackground);
    super.dispose();
  }
  int? selectedCommentId; // To track which comment is selected for reply

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: context.cardColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text(translation(context).lbl_comments, style: boldTextStyle(size: 18,fontFamily: 'Poppins',)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon:
                Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
            onPressed: () {
              Navigator.pop(context);
            }),
        actions: const [
          // IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body: BlocConsumer<CommentBloc, CommentState>(
          bloc: commentBloc,
          // listenWhen: (previous, current) => current is DrugsState,
          // buildWhen: (previous, current) => current is! DrugsState,
          listener: (BuildContext context, CommentState state) {
            if (state is DataError) {

            }
          },
          builder: (context, state) {
            if (state is PaginationLoadingState) {
              return CommentListShimmer();
            } else if (state is PaginationLoadedState) {

              // print(state.drugsModel.length);
              if( commentBloc.postList.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 60.0),
                  child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: commentBloc.postList.length,
                      itemBuilder: (context, index) {
                        if (commentBloc.pageNumber <=
                            commentBloc.numberOfPage) {
                          if (index == commentBloc.postList.length -
                              commentBloc.nextPageTrigger) {
                            commentBloc.add(CheckIfNeedMoreDataEvent(
                              postId: widget.id,
                                index: index));
                          }
                        }
                        if (commentBloc.numberOfPage !=
                            commentBloc.pageNumber - 1 &&
                            index >= commentBloc.postList.length - 1) {
                          return SizedBox(
                              height: 200,
                              child: CommentListShimmer());
                        }
                          return SVCommentComponent(
                              postId: widget.id.toString(),
                              onReplySelected: (commentId) {
                                setState(() {
                                  selectedCommentId = (selectedCommentId ==
                                      commentBloc.postList[index].id)
                                      ? null
                                      : commentId;
                                });
                              },
                              selectedCommentId: selectedCommentId,
                              commentBloc: commentBloc,
                              comment: commentBloc.postList[index]);

                      }
                  ),
                );
              }else {
                return  Center(
                  child: Text(translation(context).msg_no_comments),
                );
              }
            } else if(state is DataError){
              return RetryWidget(errorMessage: translation(context).msg_something_went_wrong_retry, onRetry: (){
                try {
                  commentBloc.add(LoadPageEvent(postId: widget.id ?? 0,page: 1));

                } catch (e) {
                  debugPrint(e.toString());
                }

              });
            }
            return Container();
          }),
      // Stack(
      //   alignment: Alignment.bottomCenter,
      //   children: [
      //     SingleChildScrollView(
      //       child: Column(
      //         children: commentBloc.postList.map((e) {
      //           return SVCommentComponent(comment: e);
      //         }).toList(),
      //       ),
      //     ),
      //     // SVCommentReplyComponent(),
      //   ],
      // ),
      bottomSheet: Container(
        color: svGetBgColor(),
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.only(bottom: 16),
        child: SVCommentReplyComponent(commentBloc, widget.id, (value) {
          if (value.isNotEmpty) {
            commentBloc.add(PostCommentEvent(postId: widget.id, comment: value));
            value = '';
            // int index= homeBloc.postList.indexWhere((post)=>post.id==id);
            //  homeBloc.postList[index].comments!.add(Comments());
          }
        }),
      ),
    );
  }
}

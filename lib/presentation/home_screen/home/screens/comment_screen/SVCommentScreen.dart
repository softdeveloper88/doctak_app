import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVCommentComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVCommentReplyComponent.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/presentation/home_screen/models/SVCommentModel.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class SVCommentScreen extends StatefulWidget {
  int id;

  SVCommentScreen({required this.id, Key? key}) : super(key: key);

  @override
  State<SVCommentScreen> createState() => _SVCommentScreenState();
}

class _SVCommentScreenState extends State<SVCommentScreen> {
   CommentBloc commentBloc = CommentBloc();

  @override
  void initState() {
    commentBloc.add(LoadPageEvent(postId: widget.id ?? 0));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cardColor,
      appBar: AppBar(
        backgroundColor: context.cardColor,
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('Comments', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),
      body: BlocConsumer<CommentBloc, CommentState>(
          bloc: commentBloc,
          // listenWhen: (previous, current) => current is DrugsState,
          // buildWhen: (previous, current) => current is! DrugsState,
          listener: (BuildContext context, CommentState state) {
            if (state is DataError) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: Text(state.errorMessage),
                ),
              );
            }
          },
          builder: (context, state) {
            print("state $state");
            if (state is PaginationLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PaginationLoadedState) {
              // print(state.drugsModel.length);
              return ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: commentBloc.postList.length,
                  itemBuilder: (context, index) {
                    // if (commentBloc.pageNumber <=
                    //     commentBloc.numberOfPage) {
                    //   if (index ==
                    //       commentBloc.postList.length -
                    //           commentBloc.nextPageTrigger) {
                    //     commentBloc
                    //         .add(CheckIfNeedMoreDataEvent(index: index));
                    //   }
                    // }
                    // return commentBloc.numberOfPage !=
                    //     commentBloc.pageNumber - 1 &&
                    //     index >= commentBloc.postList.length - 1
                    //     ? const Center(
                    //   child: CircularProgressIndicator(),
                    // ) :
                    return SVCommentComponent(
                        comment: commentBloc.postList[index]);
                  });
            } else {
              return const Center(child: Text("No Comment Found"));
            }
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
      bottomSheet:  SVCommentReplyComponent(commentBloc,widget.id),
    );
  }
}

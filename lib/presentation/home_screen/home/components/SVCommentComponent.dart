import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../../utils/SVCommon.dart';
import '../screens/comment_screen/reply_comment_list_widget.dart';
import 'SVCommentReplyComponent.dart';

class SVCommentComponent extends StatefulWidget {
  final PostComments comment;
  CommentBloc commentBloc;
  String postId;
  final int? selectedCommentId; // ID of the currently selected comment for reply
  final Function(int) onReplySelected; // Callback when Reply button is clicked



  SVCommentComponent({required this.postId,required this.comment, required this.commentBloc,this.selectedCommentId,required this.onReplySelected});

  @override
  State<SVCommentComponent> createState() => _SVCommentComponentState();
}

class _SVCommentComponentState extends State<SVCommentComponent> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              SVProfileFragment(userId: widget.comment.commenter?.id??'')
                  .launch(context);
            },
            child: CircleAvatar(
              backgroundImage:
                  NetworkImage(widget.comment.commenter?.profilePic??''),
              radius: 24.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: InkWell(
                        onTap: () {
                          SVProfileFragment(userId: widget.comment.commenter?.id??"")
                              .launch(context);
                        },
                        child: RichText(
                            textAlign: TextAlign.left,
                            text: TextSpan(
                              style: TextStyle(
                                  fontFamily:  'Poppins',
                                  fontSize: 12.sp, color: svGetBodyColor()),
                              children: <TextSpan>[
                                // TextSpan(text: title),
                                TextSpan(
                                    text: '${widget.comment.commenter?.firstName??''} ${widget.comment.commenter?.lastName??''}',
                                    style: const TextStyle(
                                        fontFamily:  'Poppins',
                                        fontWeight: FontWeight.w500)),
                                TextSpan(
                                    text: ' ${timeAgo.format(DateTime.parse(widget.comment.createdAt!))}',

                                  style: TextStyle(
                                    fontFamily:  'Poppins',
                                    fontSize: 12.0,
                                    color: Colors.grey[600],
                                  ))
                              ],
                            )),
                      ),

                    ),
                    const Spacer(),
                    if (widget.comment.commenter?.id == AppData.logInUserId)
                      Expanded(
                        child: PopupMenuButton(
                          itemBuilder: (context) {
                            return [
                              PopupMenuItem(
                                child: Builder(builder: (context) {
                                  return Column(
                                    children: ["Delete"].map((String item) {
                                      return PopupMenuItem(
                                        value: item,
                                        child: Text(item),
                                      );
                                    }).toList(),
                                  );
                                }),
                              ),
                            ];
                          },
                          onSelected: (value) {
                            if (value == 'Delete') {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return CustomAlertDialog(
                                        title:
                                            'Are you sure want to delete comment ?',
                                        callback: () {
                                          widget.commentBloc.add(
                                              DeleteCommentEvent(
                                                  commentId: widget.comment.id
                                                      .toString()));
                                          Navigator.of(context).pop();
                                        });
                                  });
                            }
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  widget.comment.comment ?? 'No Name',
                  style: const TextStyle(fontSize: 14.0, fontFamily:  'Poppins',),
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        widget.onReplySelected(widget.comment.id ?? 0);
                      },
                      child: Text(
                        '${widget.comment.replyCount} Reply',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        widget.commentBloc.add(LikeReplyComment(commentId:widget.comment.id.toString()));
                        // widget.comment.userHasLiked=true;
                            print(widget.comment.id);
                        if(!(widget.comment.userHasLiked??true)){
                          widget.comment.reactionCount= (widget.comment.reactionCount??0)+1;
                          widget.comment.userHasLiked=true;

                        }else{
                          if((widget.comment.reactionCount??0)>0) {
                            widget.comment.reactionCount = (widget.comment
                                .reactionCount ?? 0) - 1;
                          }
                          widget.comment.userHasLiked=false;

                        }
                        print(widget.comment.userHasLiked);
                      },
                      child:
                      // ReactionButton<String>(
                      //   onReactionChanged: (Reaction<String>? reaction) {
                      //     debugPrint('Selected value: ${reaction?.value}');
                      //   },
                      //   reactions: <Reaction<String>>[
                      //     Reaction<String>(
                      //       value: 'like',
                      //       icon: widget,
                      //     ),
                      //     Reaction<String>(
                      //       value: 'love',
                      //       icon: widget,
                      //     ),
                      //   ],
                        // initialReaction: Reaction<String>(
                        //   value: 'like',
                        //   icon: widget,
                        // ),
                      //   selectedReaction: Reaction<String>(
                      //     value: 'like_fill',
                      //     icon: widget,
                      //   ), itemSize: Size.infinite,
                      // )
                      Text(
                        widget.comment.userHasLiked??false ? '${widget.comment.reactionCount}Liked':'${widget.comment.reactionCount}Like',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Row(
                    //   children: [
                    //     Text(
                    //       '1',
                    //       style: TextStyle(
                    //         fontSize: 13.0,
                    //         color: Colors.red[400],
                    //       ),
                    //     ),
                    //     const SizedBox(width: 4.0),
                    //     const Icon(
                    //       Icons.favorite,
                    //       size: 16.0,
                    //       color: Colors.red,
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
                if(widget.selectedCommentId==widget.comment.id)ReplyCommentListWidget(commentBloc:widget.commentBloc,postId:int.parse(widget.postId),commentId:widget.selectedCommentId??0 ),
                const Divider(
                  color: Colors.grey,
                  thickness: 1,
                )
              ],
            ),
          ),
        ],
      ),
    );
    // return Container(
    //   margin: const EdgeInsets.all(4),
    //   padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), // Added top margin
    //   // decoration: BoxDecoration(
    //   //   borderRadius: BorderRadius.circular(12),
    //   //
    //   // ),
    //   child: Column(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       GestureDetector(
    //         onTap: () {
    //           SVProfileFragment(userId: widget.comment.userId).launch(context);
    //         },
    //         child: Row(
    //           crossAxisAlignment: CrossAxisAlignment.center,
    //           mainAxisAlignment: MainAxisAlignment.start,
    //           children: [
    //             CircleAvatar(
    //               radius: 24,
    //               backgroundImage: NetworkImage(
    //                   '${AppData.imageUrl}${widget.comment.profilePic}'),
    //             ),
    //             const SizedBox(width: 12),
    //             Row(
    //               crossAxisAlignment: CrossAxisAlignment.start,
    //               children: [
    //                 Text(
    //                   widget.comment.name ?? 'No Name',
    //                   style: const TextStyle(
    //                       fontSize: 16, fontWeight: FontWeight.bold),
    //                 ),
    //                 const SizedBox(
    //                     width: 6), // Added margin between name and verified icon
    //                 Image.asset('images/socialv/icons/ic_TickSquare.png',
    //                     height: 14, width: 14, fit: BoxFit.cover),
    //               ],
    //             ),
    //             const Spacer(),
    //             if (widget.comment.userId == AppData.logInUserId)
    //               PopupMenuButton(
    //                 itemBuilder: (context) {
    //                   return [
    //                     PopupMenuItem(
    //                       child: Builder(builder: (context) {
    //                         return Column(
    //                           children: ["Delete"].map((String item) {
    //                             return PopupMenuItem(
    //                               value: item,
    //                               child: Text(item),
    //                             );
    //                           }).toList(),
    //                         );
    //                       }),
    //                     ),
    //                   ];
    //                 },
    //                 onSelected: (value) {
    //                   if (value == 'Delete') {
    //                     showDialog(
    //                         context: context,
    //                         builder: (BuildContext context) {
    //                           return CustomAlertDialog(
    //                               title:
    //                                   'Are you sure want to delete comment ?',
    //                               callback: () {
    //                                 widget.commentBloc.add(DeleteCommentEvent(
    //                                     commentId:
    //                                         widget.comment.id.toString()));
    //                                 Navigator.of(context).pop();
    //                               });
    //                         });
    //                   }
    //                 },
    //               )
    //
    //             //            IconButton(
    //             // onPressed: (){
    //             //
    //             // },
    //             //            icon:const Icon(Icons.delete,color: Colors.red,))
    //             //
    //           ],
    //         ),
    //       ),
    //       const SizedBox(height: 8),
    //       Text(widget.comment.comment ?? '',
    //           style: TextStyle(color: svGetBodyColor(), fontSize: 16)
    //           // TextStyle(color: Colors.grey[800], fontSize: 16),
    //           ),
    //       Text(
    //         timeAgo.format(DateTime.parse(widget.comment.createdAt!)),
    //         style: const TextStyle(color: Colors.grey, fontSize: 12),
    //       ),
    //       Divider(
    //         color: Colors.grey[300],
    //       )
    //     ],
    //   ),
    // );
  }
}

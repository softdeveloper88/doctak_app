import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../../utils/SVCommon.dart';

class SVCommentComponent extends StatefulWidget {
  final PostComments comment;
  CommentBloc commentBloc;

  SVCommentComponent({required this.comment, required this.commentBloc});

  @override
  State<SVCommentComponent> createState() => _SVCommentComponentState();
}

class _SVCommentComponentState extends State<SVCommentComponent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), // Added top margin
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(12),
      //
      // ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              SVProfileFragment(userId: widget.comment.userId).launch(context);
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(
                      '${AppData.imageUrl}${widget.comment.profilePic}'),
                ),
                const SizedBox(width: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.comment.name ?? 'No Name',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                        width:
                            6), // Added margin between name and verified icon
                    Image.asset('images/socialv/icons/ic_TickSquare.png',
                        height: 14, width: 14, fit: BoxFit.cover),
                  ],
                ),
                const Spacer(),
                if (widget.comment.userId == AppData.logInUserId)
                  PopupMenuButton(
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
                                    widget.commentBloc.add(DeleteCommentEvent(
                                        commentId:
                                            widget.comment.id.toString()));
                                    Navigator.of(context).pop();
                                  });
                            });
                      }
                    },
                  )

                //            IconButton(
                // onPressed: (){
                //
                // },
                //            icon:const Icon(Icons.delete,color: Colors.red,))
                //
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(widget.comment.comment ?? '',
              style: GoogleFonts.poppins(color: svGetBodyColor(), fontSize: 16)
              // TextStyle(color: Colors.grey[800], fontSize: 16),
              ),
          Text(
            timeAgo.format(DateTime.parse(widget.comment.createdAt!)),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Divider(
            color: Colors.grey[300],
          )
        ],
      ),
    );
  }
}

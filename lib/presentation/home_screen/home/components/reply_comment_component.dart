import 'package:doctak_app/data/models/post_comment_model/reply_comment_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';
 import 'package:timeago/timeago.dart' as timeAgo;
import '../../../../core/utils/app/AppData.dart';

class ReplyCommentComponent extends StatelessWidget {
   ReplyCommentComponent(this.replyCommentList,this.onDeleteComment,this.onUpdateComment,{super.key});
  CommentsModel replyCommentList;
  Function? onDeleteComment;
  Function? onUpdateComment;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              SVProfileFragment(userId: replyCommentList.commentableId??'')
                  .launch(context);
            },
            child: CircleAvatar(
              backgroundImage:
              NetworkImage(replyCommentList.commenter?.profilePic??'',),
              radius: 15.0,
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
                          SVProfileFragment(userId: replyCommentList.commenterId??"")
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
                                    text: replyCommentList.commenter?.name??'',
                                    style: const TextStyle(
                                        fontFamily:  'Poppins',
                                        fontWeight: FontWeight.w500)),
                                TextSpan(
                                    text: ' ${timeAgo.format(DateTime.parse(replyCommentList.createdAt!))}',

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
                    if (replyCommentList.commenterId == AppData.logInUserId)
                      Expanded(
                        child: PopupMenuButton(
                          itemBuilder: (context) {
                            return [
                              PopupMenuItem(
                                child: Builder(builder: (context) {
                                  return Column(
                                    children: ["Delete","Update"].map((String item) {
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
                                          onDeleteComment!();
                                          Navigator.of(context).pop();
                                        });
                                  });
                            }else if (value == 'Update') {
                             onUpdateComment!();
                            }
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  replyCommentList.comment ?? 'No Name',
                  style: const TextStyle(fontSize: 14.0, fontFamily:  'Poppins',),
                ),
                const SizedBox(height: 8.0),
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
  }
}

import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/utils/app/AppData.dart';
import '../screens/comment_screen/bloc/comment_bloc.dart';


class SVCommentReplyComponent extends StatelessWidget {
  CommentBloc commentBloc;
  int id;
   SVCommentReplyComponent(this.commentBloc,this.id, {Key? key}) : super(key: key);
TextEditingController commentController=TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: svGetBgColor(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Divider(indent: 16, endIndent: 16, height: 20),
          Row(
            children: [
              16.width,
              Image.network(AppData.imageUrl + AppData.profile_pic, height: 48, width: 48, fit: BoxFit.cover).cornerRadiusWithClipRRect(50),
              10.width,
              SizedBox(
                width: context.width() * 0.6,
                child: AppTextField(
                  controller: commentController,
                  textFieldType: TextFieldType.OTHER,
                  decoration: InputDecoration(
                    hintText: 'Write a comment',
                    hintStyle: secondaryTextStyle(color: svGetBodyColor()),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              ),
              TextButton(onPressed: () {
                if(commentController.text.isNotEmpty) {
                  commentBloc.add(PostCommentEvent(
                      postId: id, comment: commentController.text));
                  commentController.text='';
                }
              }, child: Text('Post', style: secondaryTextStyle(color: SVAppColorPrimary)))
            ],
          ),
        ],
      ),
    );
  }
}

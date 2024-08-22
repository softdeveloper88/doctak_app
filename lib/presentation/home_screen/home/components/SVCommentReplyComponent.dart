import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../../core/utils/app/AppData.dart';
import '../screens/comment_screen/bloc/comment_bloc.dart';

class SVCommentReplyComponent extends StatelessWidget {
  CommentBloc commentBloc;
  Function(String) onPostComment;
  int id;
  SVCommentReplyComponent(this.commentBloc, this.id, this.onPostComment,
      {Key? key})
      : super(key: key);
  TextEditingController commentController = TextEditingController();
  FocusNode focusNode = FocusNode();

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
              CustomImageView(
                      imagePath: AppData.imageUrl + AppData.profile_pic,
                      height: 48,
                      width: 48,
                      fit: BoxFit.cover)
                  .cornerRadiusWithClipRRect(50),
              10.width,
              Container(
                padding: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: svGetBodyColor())),
                child: Row(
                  children: [
                    SizedBox(
                      width: context.width() * 0.6,
                      child: AppTextField(
                        focus: focusNode,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        controller: commentController,
                        textFieldType: TextFieldType.MULTILINE,
                        decoration: InputDecoration(
                          hintText: 'Write a comment',
                          hintStyle:
                              secondaryTextStyle(color: svGetBodyColor()),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                  onPressed: () {
                    if (commentController.text.isNotEmpty) {
                      onPostComment(commentController.text);
                      commentController.text = '';
                      focusNode.unfocus();

                    }
                  },
                  child: Text('Post',
                      style: secondaryTextStyle(color: SVAppColorPrimary))),
            ],
          ),
        ],
      ),
    );
  }
}

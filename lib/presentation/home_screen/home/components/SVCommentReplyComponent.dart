import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/utils/app/AppData.dart';
import '../screens/comment_screen/bloc/comment_bloc.dart';

class SVCommentReplyComponent extends StatefulWidget {
  CommentBloc commentBloc;
  Function(String) onPostComment;
  String? commentValue;
   double? width;
   int id;
  SVCommentReplyComponent(this.commentBloc, this.id, this.onPostComment,{this.commentValue,this.width,
      Key? key})
      : super(key: key);

  @override
  State<SVCommentReplyComponent> createState() => _SVCommentReplyComponentState();
}

class _SVCommentReplyComponentState extends State<SVCommentReplyComponent> {
  TextEditingController commentController = TextEditingController();

  FocusNode focusNode = FocusNode();
  @override
  void dispose() {
    focusNode.unfocus();
    super.dispose();
  }
  @override
  void initState() {
   commentController=TextEditingController(text: widget.commentValue??'');
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      color: svGetBgColor(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Divider(indent: 16, endIndent: 16, height: 20),
          Row(
             mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                child: CustomImageView(
                        imagePath: AppData.imageUrl + AppData.profile_pic,
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover)
                    .cornerRadiusWithClipRRect(50),
              ),
              10.width,
              Container(
                padding: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  // border: Border.all(color: svGetBodyColor())
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          // border: Border.all(color: svGetBodyColor())
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width:widget.width??78.w,
                            child: AppTextField(
                              suffix:  TextButton(
                                  onPressed: () {
                                    if (commentController.text.isNotEmpty) {
                                      focusNode.unfocus();
                                      widget.onPostComment(commentController.text);
                                      commentController.text = '';
                                    }
                                  },
                                  child: Text('Post',
                                      style: secondaryTextStyle(color: SVAppColorPrimary,fontFamily: 'Poppins',))),
                              focus: focusNode,
                              minLines: 1,
                              // textInputAction: TextInputAction.done,
                              controller: commentController,
                              textFieldType: TextFieldType.MULTILINE,
                              decoration: InputDecoration(
                                hintText: ' Write a comment',
                                hintStyle: secondaryTextStyle(color: svGetBodyColor(),fontFamily: 'Poppins',),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                              ),
                              onFieldSubmitted: (value) {
                                // Handle done action here if needed
                                if (commentController.text.isNotEmpty) {
                                  focusNode.unfocus();
                                  widget.onPostComment(commentController.text);
                                  commentController.text = '';
                                }// Unfocus the text field to dismiss the keyboard
                              },
                            ),
                          ),
                        ],
                      ),
                    ),


                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

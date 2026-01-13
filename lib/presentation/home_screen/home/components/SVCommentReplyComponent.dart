import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
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
  SVCommentReplyComponent(
    this.commentBloc,
    this.id,
    this.onPostComment, {
    this.commentValue,
    this.width,
    Key? key,
  }) : super(key: key);

  @override
  State<SVCommentReplyComponent> createState() =>
      _SVCommentReplyComponentState();
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
    commentController = TextEditingController(text: widget.commentValue ?? '');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 16),
      color: theme.cardBackground,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: theme.primary.withOpacity(0.1),
                child: CustomImageView(
                  imagePath: AppData.imageUrl + AppData.profile_pic,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                ).cornerRadiusWithClipRRect(50),
              ),
              10.width,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.border, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SizedBox(
                      width: widget.width ?? 78.w,
                      child: AppTextField(
                        suffix: TextButton(
                          onPressed: () {
                            if (commentController.text.isNotEmpty) {
                              focusNode.unfocus();
                              widget.onPostComment(commentController.text);
                              commentController.text = '';
                            }
                          },
                          child: Text(
                            translation(context).lbl_post,
                            style: TextStyle(
                              color: theme.primary,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        focus: focusNode,
                        minLines: 1,
                        controller: commentController,
                        textFieldType: TextFieldType.MULTILINE,
                        textStyle: TextStyle(
                          color: theme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                        decoration: InputDecoration(
                          hintText: translation(context).lbl_write_a_comment,
                          hintStyle: TextStyle(
                            color: theme.textTertiary,
                            fontFamily: 'Poppins',
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                        onFieldSubmitted: (value) {
                          if (commentController.text.isNotEmpty) {
                            focusNode.unfocus();
                            widget.onPostComment(commentController.text);
                            commentController.text = '';
                          }
                        },
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

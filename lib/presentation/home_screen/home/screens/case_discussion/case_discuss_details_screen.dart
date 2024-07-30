import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/case_model/case_discuss_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_event.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/bloc/case_discussion_state.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CaseDiscussDetailsScreen extends StatefulWidget {
  CaseDiscussDetailsScreen(this.caseDiscussList, this.caseDiscussionBloc,
      {super.key});

  final Data caseDiscussList;
  final CaseDiscussionBloc caseDiscussionBloc;

  @override
  State<CaseDiscussDetailsScreen> createState() =>
      _CaseDiscussDetailsScreenState();
}

class _CaseDiscussDetailsScreenState extends State<CaseDiscussDetailsScreen> {
  late TextEditingController commentController;

  @override
  void initState() {
    super.initState();
    commentController = TextEditingController();
    widget.caseDiscussionBloc.add(
      CaseCommentPageEvent(caseId: widget.caseDiscussList.id.toString()),
    );
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.cardColor,
        iconTheme: IconThemeData(color: context.iconColor),
        title: Text('Case Details', style: boldTextStyle(size: 20)),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor()),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: CachedNetworkImage(
                          imageUrl:
                          "${AppData.imageUrl}${widget.caseDiscussList.profilePic!.validate()}",
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                        ).cornerRadiusWithClipRRect(20),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.caseDiscussList.name}',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.caseDiscussList.createdAt
                                .toString(),
                            style: GoogleFonts.roboto(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${widget.caseDiscussList.title}',
                    style: GoogleFonts.roboto(),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      const Divider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(onPressed: (){
                            widget.caseDiscussionBloc.add(CaseDiscussEvent(caseId: widget.caseDiscussList.id.toString(),type: 'case',actionType: 'likes'));

                          },icon:Icon(Icons.thumb_up_alt_outlined)),
                          const SizedBox(width: 4),
                          Text(
                              '${widget.caseDiscussList.likes} Likes'),
                          const SizedBox(width: 16),
                          const Icon(Icons.comment_outlined),
                          const SizedBox(width: 4),
                          Text(
                              '${widget.caseDiscussList.comments} Comments'),
                          const SizedBox(width: 16),
                          Text(
                              '${widget.caseDiscussList.views} Views'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          BlocConsumer<CaseDiscussionBloc, CaseDiscussionState>(
            bloc: widget.caseDiscussionBloc,
            listener: (BuildContext context, CaseDiscussionState state) {
              if (state is DataError) {
                // Handle error state
              }
            },
            builder: (context, state) {
              if (state is PaginationLoadingState) {
                return Center(
                  child: CircularProgressIndicator(
                    color: svGetBodyColor(),
                  ),
                );
              } else if (state is PaginationLoadedState) {
                return widget.caseDiscussionBloc.caseComments.comments?.isEmpty ??
                    false
                    ? const Center(
                  child: Text('No View'),
                )
                    : Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80.0),
                        itemCount: widget.caseDiscussionBloc
                            .caseComments.comments?.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundImage:
                                    CachedNetworkImageProvider(
                                        widget.caseDiscussionBloc.caseComments.comments?[index].profilePic ?? ''),
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                widget.caseDiscussionBloc
                                                    .caseComments
                                                    .comments?[index]
                                                    .name ??
                                                    '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16.0,
                                                ),
                                              ),
                                            ),
                                            // if (widget.caseDiscussList.name == AppData.name)
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
                                                              widget.caseDiscussionBloc.add(CaseDiscussEvent(caseId: widget.caseDiscussionBloc.caseComments.comments![index].id.toString(),type: 'case_comment',actionType: 'delete'));

                                                              Navigator.of(context).pop();
                                                            });
                                                      });
                                                }
                                              },
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          widget.caseDiscussionBloc
                                              .caseComments
                                              .comments?[index]
                                              .comment ??
                                              '',
                                          style: const TextStyle(
                                            fontSize: 14.0,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: TextIcon(
                                                text:'${widget.caseDiscussionBloc
                                            .caseComments
                                            .comments?[index].likes}',
                                                 suffix: const Icon(Icons.thumb_up_alt_outlined,
                                                  color: Colors.blue)),
                                              onPressed: () {
                                                widget.caseDiscussionBloc.add(CaseDiscussEvent(caseId: widget.caseDiscussionBloc.caseComments.comments![index].id.toString(),type: 'case_comment',actionType: 'likes'));

                                                // Handle like action
                                              },
                                            ),
                                            IconButton(
                                              icon: TextIcon(
                                                  text:'${widget.caseDiscussionBloc
                                                      .caseComments
                                                      .comments?[index].dislikes??'0'}',
                                                  prefix: const Icon(Icons.thumb_down_alt_outlined,
                                                      color: Colors.red)),
                                              onPressed: () {
                                                widget.caseDiscussionBloc.add(CaseDiscussEvent(caseId: widget.caseDiscussionBloc.caseComments.comments![index].id.toString(),type: 'case_comment',actionType: 'dislikes'));

                                                // Handle like action
                                              },
                                            ),

                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
              } else {
                return const Center(child: Text("No Comment Found"));
              }
            },
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: context.cardColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                          minLines: 1,
                          textInputAction: TextInputAction.newline,
                          controller: commentController,
                          textFieldType: TextFieldType.MULTILINE,
                          decoration: InputDecoration(
                            hintText: 'Write your view',
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
                      widget.caseDiscussionBloc.add(
                        AddCaseCommentEvent(
                          caseId: widget.caseDiscussList.id.toString(),
                          comment: commentController.text.toString(),
                        ),
                      );
                      commentController.clear();
                    }
                  },
                  child: Text('Post',
                      style: secondaryTextStyle(color: SVAppColorPrimary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

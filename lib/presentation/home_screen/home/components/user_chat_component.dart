import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/models/SVStoryModel.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVConstants.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

class UserChatComponent extends StatefulWidget {
  @override
  State<UserChatComponent> createState() => _UserChatComponentState();
}

class _UserChatComponentState extends State<UserChatComponent> {
  ChatBloc chatBloc = ChatBloc();

  @override
  void initState() {
    chatBloc.add(LoadPageEvent(page: 1));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
        bloc: chatBloc,
        listener: (BuildContext context, ChatState state) {
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
          if (state is PaginationLoadedState) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Column(
                  //   children: [
                  //     Container(
                  //       margin: const EdgeInsets.symmetric(horizontal: 16),
                  //       height: 60,
                  //       width: 60,
                  //       decoration: BoxDecoration(
                  //         color: SVAppColorPrimary,
                  //         borderRadius: radius(SVAppCommonRadius),
                  //       ),
                  //       child: IconButton(
                  //           icon: const Icon(Icons.add, color: Colors.white),
                  //           onPressed: () async {
                  //
                  //           }),
                  //     ),
                  //     10.height,
                  //     Text('Recent chat',
                  //         style: secondaryTextStyle(
                  //             size: 12,
                  //             color: context.iconColor,
                  //             weight: FontWeight.w500)),
                  //   ],
                  // ),
                  HorizontalList(
                    spacing: 16,
                    itemCount: chatBloc.contactsList.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: SVAppColorPrimary, width: 2),
                              borderRadius: radius(14),
                            ),
                            child: chatBloc.contactsList[index].profilePic
                                        ?.isEmpty ??
                                    true
                                ? Image.asset(
                                    'images/socialv/faces/face_2.png',
                                    height: 58,
                                    width: 58,
                                    fit: BoxFit.cover,
                                  ).cornerRadiusWithClipRRect(SVAppCommonRadius)
                                : CachedNetworkImage(
                                    imageUrl:
                                        '${AppData.imageUrl}${chatBloc.contactsList[index].profilePic}',
                                    height: 58,
                                    width: 58,
                                    fit: BoxFit.cover,
                                  ).cornerRadiusWithClipRRect(
                                    SVAppCommonRadius),
                          ).onTap(() {
                            print(chatBloc.contactsList[index].id);
                            // ChatRoomScreen(username: '${chatBloc.contactsList[index].firstName} ${chatBloc.contactsList[index].lastName}',profilePic: '${chatBloc.contactsList[index].profilePic}',id: '',roomId: '${chatBloc.contactsList[index].roomId}',).launch(context);
                            SVProfileFragment(
                                    userId: chatBloc.contactsList[index].id)
                                .launch(context);

                            // SVStoryScreen(story: storyList[index])
                            //     .launch(context);
                          }),
                          10.height,
                          Text(
                              '${chatBloc.contactsList[index].firstName.validate()} ${chatBloc.contactsList[index].lastName.validate()}',
                              style: secondaryTextStyle(
                                  size: 12,
                                  color: context.iconColor,
                                  weight: FontWeight.w500)),
                        ],
                      );
                    },
                  )
                ],
              ),
            );
          } else {
            return Container();
          }
        });
  }
}

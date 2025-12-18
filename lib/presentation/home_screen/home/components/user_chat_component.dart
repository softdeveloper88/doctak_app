import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

class UserChatComponent extends StatefulWidget {
  const UserChatComponent({Key? key}) : super(key: key);

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
    return BlocBuilder<ChatBloc, ChatState>(
        bloc: chatBloc,
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
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                const BoxShadow(
                                  color: Color(0x4D9E9E9E),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: chatBloc
                                    .contactsList[index].profilePic!.isEmpty
                                ? Image.asset('images/socialv/faces/face_5.png',
                                        height: 56,
                                        width: 56,
                                        fit: BoxFit.cover)
                                    .cornerRadiusWithClipRRect(8)
                                    .cornerRadiusWithClipRRect(8)
                                : AppCachedNetworkImage(
                                    imageUrl:
                                      '${AppData.imageUrl}${chatBloc.contactsList[index].profilePic}',
                                    height: 56,
                                    width: 56,
                                    fit: BoxFit.cover)
                                    .cornerRadiusWithClipRRect(30),
                          ).onTap(() {
                            print(chatBloc.contactsList[index].id);
                            // ChatRoomScreen(username: '${chatBloc.contactsList[index].firstName} ${chatBloc.contactsList[index].lastName}',profilePic: '${chatBloc.contactsList[index].profilePic}',id: '',roomId: '${chatBloc.contactsList[index].roomId}',).launch(context);
                            SVProfileFragment(
                                    userId: chatBloc.contactsList[index].id)
                                .launch(context);

                            // SVStoryScreen(story: storyList[index])
                            //     .launch(context);
                          }),
                          // ),
                          // Container(
                          //   decoration: BoxDecoration(
                          //     // border: Border.all(
                          //     //     color: SVAppColorPrimary, width: 2),
                          //     borderRadius: radius(100),
                          //   ),
                          //   child: chatBloc.contactsList[index].profilePic
                          //               ?.isEmpty ??
                          //           true
                          //       ? Image.asset(
                          //           'images/socialv/faces/face_2.png',
                          //           height: 58,
                          //           width: 58,
                          //           fit: BoxFit.cover,
                          //         ).cornerRadiusWithClipRRect(SVAppCommonRadius)
                          //       : CircleAvatar(
                          //         child: CachedNetworkImage(
                          //             imageUrl:
                          //                 '${AppData.imageUrl}${chatBloc.contactsList[index].profilePic}',
                          //             height: 58,
                          //             width: 58,
                          //             fit: BoxFit.cover,
                          //           ).cornerRadiusWithClipRRect(
                          //             SVAppCommonRadius),
                          //       ),
                          // ).onTap(() {
                          //   print(chatBloc.contactsList[index].id);
                          //   // ChatRoomScreen(username: '${chatBloc.contactsList[index].firstName} ${chatBloc.contactsList[index].lastName}',profilePic: '${chatBloc.contactsList[index].profilePic}',id: '',roomId: '${chatBloc.contactsList[index].roomId}',).launch(context);
                          //   SVProfileFragment(
                          //           userId: chatBloc.contactsList[index].id)
                          //       .launch(context);
                          //
                          //   // SVStoryScreen(story: storyList[index])
                          //   //     .launch(context);
                          // }),
                          10.height,
                          SizedBox(
                            width: 60,
                            child: Text(
                                overflow: TextOverflow.ellipsis,
                                '${chatBloc.contactsList[index].firstName.validate()} ${chatBloc.contactsList[index].lastName.validate()}',
                                style: secondaryTextStyle(
                                    size: 12,
                                    color: context.iconColor,
                                    weight: FontWeight.w500)),
                          ),
                        ],
                      );
                    },
                  )
                ],
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}

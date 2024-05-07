import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/search_contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

import 'chat_room_screen.dart';

class UserChatScreen extends StatefulWidget {
  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  ChatBloc chatBloc = ChatBloc();

  @override
  void initState() {
    chatBloc.add(LoadPageEvent(page: 1));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:svGetScaffoldColor(),
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              SearchContactScreen().launch(context);
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.more_vert),
          //   onPressed: () {
          //     // Add more options functionality
          //   },
          // ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
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
          if (state is PaginationLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PaginationLoadedState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (chatBloc.groupList.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Groups',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (chatBloc.groupList.isNotEmpty)
                  SizedBox(
                    height: 100.0,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: chatBloc.groupList.length,
                      itemBuilder: (context, index) {
                        final bloc = chatBloc;

                        if (bloc.pageNumber <= bloc.numberOfPage) {
                          if (index ==
                              bloc.groupList.length - bloc.nextPageTrigger) {
                            bloc.add(CheckIfNeedMoreDataEvent(index: index));
                          }
                        }
                        return bloc.numberOfPage != bloc.pageNumber - 1 &&
                                index >= bloc.groupList.length - 1
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : GestureDetector(
                                onTap: () {
                                  ChatRoomScreen(
                                    username:
                                        '${bloc.groupList[index].groupName}',
                                    profilePic: '',
                                    id: '',
                                    roomId: '${bloc.groupList[index].roomId}',
                                  ).launch(context);
                                },
                                child: Container(
                                  width: 200,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Card(
                                    elevation: 0,
                                    color: Colors.transparent,
                                    child: ListTile(
                                      title: Text(
                                        bloc.groupList[index].groupName ??
                                            'Unknown',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      subtitle: Text(
                                        bloc.groupList[index].latestMessage ??
                                            '',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                      },
                    ),
                  ),
                if (chatBloc.contactsList.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Contacts',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (chatBloc.contactsList.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: chatBloc.contactsList.length,
                      itemBuilder: (context, index) {
                        var bloc = chatBloc;
                        if (bloc.pageNumber <= bloc.numberOfPage) {
                          if (index ==
                              bloc.contactsList.length - bloc.nextPageTrigger) {
                            bloc.add(CheckIfNeedMoreDataEvent(index: index));
                          }
                        }
                        return bloc.numberOfPage != bloc.pageNumber - 1 &&
                                index >= bloc.contactsList.length - 1
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            :
                            // Card(
                            //
                            //   elevation: 2,
                            //   shape: RoundedRectangleBorder(
                            //     borderRadius: BorderRadius.circular(8),
                            //   ),
                            //   child: ListTile(
                            //     leading: InkWell(
                            //       onTap: () {
                            //         // Handle profile picture tap
                            //       },
                            //       child: Container(
                            //         width: 60,
                            //         height: 60,
                            //         decoration: BoxDecoration(
                            //           shape: BoxShape.circle,
                            //           boxShadow: [
                            //             BoxShadow(
                            //               color: Colors.grey.withOpacity(0.5),
                            //               spreadRadius: 2,
                            //               blurRadius: 5,
                            //               offset: const Offset(0, 3),
                            //             ),
                            //           ],
                            //         ),
                            //         child: CircleAvatar(
                            //           radius: 30,
                            //           backgroundImage: CachedNetworkImageProvider(
                            //             '${AppData.imageUrl}${bloc.contactsList[index].profilePic}',
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //     title: Text(
                            //       '${bloc.contactsList[index].firstName} ${bloc.contactsList[index].lastName}',
                            //       style: const TextStyle(
                            //         fontWeight: FontWeight.bold,
                            //         fontSize: 16,
                            //         color: Colors.black87,
                            //       ),
                            //     ),
                            //     subtitle: Text(
                            //       bloc.contactsList[index].latestMessage ?? 'No recent messages',
                            //       style: TextStyle(
                            //         fontSize: 14,
                            //         color: Colors.grey[600],
                            //       ),
                            //     ),
                            //     onTap: () {
                            //       ChatRoomScreen(
                            //         username: '${bloc.contactsList[index].firstName} ${bloc.contactsList[index].lastName}',
                            //         profilePic: '${bloc.contactsList[index].profilePic}',
                            //         id: '',
                            //         roomId: '${bloc.contactsList[index].roomId}',
                            //       ).launch(context);
                            //       // Add navigation logic or any other action on contact tap
                            //     },
                            //   )
                            //
                            // );
                            Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: () {
                                    ChatRoomScreen(
                                      username:
                                          '${bloc.contactsList[index].firstName} ${bloc.contactsList[index].lastName}',
                                      profilePic:
                                          '${bloc.contactsList[index].profilePic}',
                                      id: '',
                                      roomId:
                                          '${bloc.contactsList[index].roomId}',
                                    ).launch(context);
                                    // Add navigation logic or any other action on contact tap
                                  },
                                  child: Material(
                                    elevation: 2,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16.0, horizontal: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    // SVProfileFragment(userId:bloc.contactsList[index].id).launch(context);
                                                  },
                                                  child: Container(
                                                    width: 50,
                                                    height: 50,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.grey
                                                              .withOpacity(0.5),
                                                          spreadRadius: 2,
                                                          blurRadius: 5,
                                                          offset: const Offset(
                                                              0, 3),
                                                        ),
                                                      ],
                                                    ),
                                                    child: bloc
                                                                .contactsList[
                                                                    index]
                                                                .profilePic ==
                                                            ''
                                                        ? Image.asset(
                                                                'images/socialv/faces/face_5.png',
                                                                height: 56,
                                                                width: 56,
                                                                fit: BoxFit
                                                                    .cover)
                                                            .cornerRadiusWithClipRRect(
                                                                8)
                                                            .cornerRadiusWithClipRRect(
                                                                8)
                                                        : CachedNetworkImage(
                                                                imageUrl:
                                                                    '${AppData.imageUrl}${bloc.contactsList[index].profilePic.validate()}',
                                                                height: 56,
                                                                width: 56,
                                                                fit: BoxFit
                                                                    .cover)
                                                            .cornerRadiusWithClipRRect(
                                                                30),
                                                  ),
                                                ),
                                                10.width,
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        SizedBox(
                                                            width: 150,
                                                            child: Text(
                                                                "${bloc.contactsList[index].firstName.validate()} ${bloc.contactsList[index].lastName.validate()}",
                                                                overflow:
                                                                    TextOverflow
                                                                        .clip,
                                                                style:
                                                                    boldTextStyle())),
                                                        6.width,
                                                        // bloc.contactsList[index].isCurrentUser.validate()
                                                        //     ? Image.asset('images/socialv/icons/ic_TickSquare.png', height: 14, width: 14, fit: BoxFit.cover)
                                                        //     : const Offstage(),
                                                      ],
                                                    ),
                                                    Text(
                                                        bloc.contactsList[index]
                                                            .latestMessage
                                                            .validate(),
                                                        style: secondaryTextStyle(
                                                            color:
                                                                svGetBodyColor())),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // isLoading ? const CircularProgressIndicator():  AppButton(
                                          //   shapeBorder: RoundedRectangleBorder(borderRadius: radius(10)),
                                          //   text:widget.element.isFollowedByCurrentUser == true ? 'Unfollow':'Follow',
                                          //   textStyle: boldTextStyle(color:  widget.element.isFollowedByCurrentUser != true ?SVAppColorPrimary:buttonUnSelectColor,size: 10),
                                          //   onTap:  () async {
                                          //     setState(() {
                                          //       isLoading = true; // Set loading state to true when button is clicked
                                          //     });
                                          //
                                          //     // Perform API call
                                          //     widget.onTap();
                                          //
                                          //     setState(() {
                                          //       isLoading = false; // Set loading state to false after API response
                                          //     });
                                          //   },
                                          //   elevation: 0,
                                          //   color: widget.element.isFollowedByCurrentUser == true ?SVAppColorPrimary:buttonUnSelectColor,
                                          // ),
                                          // ElevatedButton(
                                          //   // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                          //   onPressed: () async {
                                          //     setState(() {
                                          //       isLoading = true; // Set loading state to true when button is clicked
                                          //     });
                                          //
                                          //     // Perform API call
                                          //     await widget.onTap();
                                          //
                                          //     setState(() {
                                          //       isLoading = false; // Set loading state to false after API response
                                          //     });
                                          //   },
                                          //   child: isLoading
                                          //       ? CircularProgressIndicator() // Show progress indicator if loading
                                          //       : Text(widget.element.isFollowedByCurrentUser == true ? 'Unfollow' : 'Follow', style: boldTextStyle(color: Colors.white, size: 10)),
                                          //   style: ElevatedButton.styleFrom(
                                          //     // primary: Colors.blue, // Change button color as needed
                                          //     elevation: 0,
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                      },
                    ),
                  )
                else
                  Expanded(
                      child: Center(
                    child:
                        Text("No chat found", style: boldTextStyle(size: 16)),
                  )),
                if (AppData.isShowGoogleBannerAds ?? false) BannerAdWidget()
              ],
            );
          } else if (state is DataError) {
            return Expanded(
              child: Center(
                child: Text(state.errorMessage),
              ),
            );
          } else {
            return const Center(child: Text('Something went wrong'));
          }
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Add functionality to start a new chat
      //   },
      //   child: const Icon(Icons.message),
      // ),
    );
  }
}

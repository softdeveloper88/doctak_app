import 'dart:async';
import 'dart:convert';

import 'package:doctak_app/ads_setting/ads_widget/banner_ads_widget.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVCommon.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/search_contact_screen.dart';
import 'package:doctak_app/widgets/retry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../Pusher/PusherConfig.dart';
import 'chat_room_screen.dart';

class UserChatScreen extends StatefulWidget {
  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen>
    with WidgetsBindingObserver {
  ChatBloc chatBloc = ChatBloc();

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    setStatusBarColor(svGetScaffoldColor());
    ConnectPusher();
    chatBloc.add(LoadPageEvent(page: 1));
    super.initState();
  }

  String sanitizeString(String input) {
    try {
      return String.fromCharCodes(input.codeUnits);
    } catch (e) {
      return translation(context).msg_invalid_string;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('state life');
    if (state == AppLifecycleState.resumed) {
      print("state life $state");
      ConnectPusher();
    }
  }

  void onEvent(PusherEvent event) {
    print("onEvent data: $event");
    Map<String, dynamic> jsonMap = jsonDecode(event.data.toString());
    // var data=json.encode(event);
    // print(jsonDecode(event.eventName));
    // print('onEventName ${jsonDecode(event.eventName)}');
    // if(event.eventName=='client-typing'){
    //   onTypingStarted();
    // }
    print('data click ${jsonMap['from_id']}');
    FromId = jsonMap['from_id'];
    setState(() {});
  }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print("onSubscriptionSucceeded: $channelName data: $data");
  }

  void onSubscriptionError(String message, dynamic e) {
    print("onSubscriptionError: $message Exception: $e");
  }

  void onDecryptionFailure(String event, String reason) {
    print("onDecryptionFailure: $event reason: $reason");
  }

  void onMemberAdded(String channelName, PusherMember member) {
    print("onMemberAdded: $channelName member: $member");
  }

  void onMemberRemoved(String channelName, PusherMember member) {
    print("onMemberRemoved: $channelName member: $member");
  }

  void onError(String message, int? code, dynamic e) {
    print("onError: $message code: $code exception: $e");
  }

  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  late PusherChannel clientListenChannel;
  late PusherChannel clientSendChannel;
  bool isSomeoneTyping = false;
  String? FromId;

  Future<dynamic> onAuthorizer(
      String channelName, String socketId, dynamic options) async {
    final Uri uri = Uri.parse("${AppData.chatifyUrl}chat/auth");

    // Build query parameters
    final Map<String, String> queryParams = {
      'socket_id': socketId,
      'channel_name': channelName,
    };

    final response = await http.post(
      uri.replace(queryParameters: queryParams),
      headers: {
        'Authorization': 'Bearer ${AppData.userToken!}',
      },
    );

    if (response.statusCode == 200) {
      final String data = response.body;

      return jsonDecode(data);
    } else {
      throw Exception(translation(context).msg_pusher_auth_failed);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addObserver(this);
    _timer?.cancel();
    _ampTimer?.cancel();
    _timerChat?.cancel();
    super.dispose();
  }

  void onTypingStarted() {
    setState(() {
      print('FromId $FromId');
      isSomeoneTyping = true;
    });
  }

  Future<void> _refresh() async {
    // Simulate network request
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      chatBloc.add(LoadPageEvent(page: 1));
    });
  }

  void onTypingStopped() {
    print('FromId $FromId');
    setState(() {
      isSomeoneTyping = false;
    });
  }

  onSubscriptionCount(String channelName, int subscriptionCount) {}
  Timer? _timer;
  Timer? _timerChat;
  Timer? _ampTimer;
  Timer? typingTimer;

  void ConnectPusher() async {
    // Create the Pusher client
    try {
      await pusher.init(
          apiKey: PusherConfig.key,
          cluster: PusherConfig.cluster,
          useTLS: false,
          onSubscriptionSucceeded: onSubscriptionSucceeded,
          onSubscriptionError: onSubscriptionError,
          onMemberAdded: onMemberAdded,
          onMemberRemoved: onMemberRemoved,
          onEvent: onEvent,
          onDecryptionFailure: onDecryptionFailure,
          onError: onError,
          onSubscriptionCount: onSubscriptionCount,
          onAuthorizer: onAuthorizer);

      pusher.connect();

      if (pusher != null) {
        // Successfully created and connected to Pusher
        clientListenChannel = await pusher.subscribe(
          channelName: 'private-chatify.${AppData.logInUserId}',
          onMemberAdded: (member) {
            print("Member added: $member");
          },
          onMemberRemoved: (member) {
            // print("Member removed: $member");
          },
          onEvent: (event) {
            String eventName = event.eventName;
            print(eventName);

            switch (eventName) {
              case 'client-typing':
                onTypingStarted();
                // If the timer is already running, cancel it
                if (typingTimer != null && typingTimer!.isActive) {
                  typingTimer!.cancel();
                }
                // Set a timer to stop typing indicator after 2 seconds
                typingTimer = Timer(const Duration(seconds: 2), () {
                  onTypingStopped();
                  // chatBloc.add(LoadRoomMessageEvent(
                  //     page: 0, userId: widget.id, roomId: widget.roomId));
                });
                break;
              // case 'client-seen':
              // var textMessage = "";
              // var messageData = event.data;
//                 messageData = json.decode(messageData);
//                 var status = messageData['status'];
//                 if (status == "web") {
//                   final htmlMessage = event.data;
//                   var message = json.decode(htmlMessage);
//
//                   // Use the html package to parse the HTML and extract text content
//                   final document = htmlParser.parse(message['message']);
//
//                   final messageDiv = document.querySelector('.message');
//                   final textMessageWithTime = messageDiv?.text.trim() ?? "";
//
// // Split the textMessageWithTime by the "time ago" portion
//                   final parts = textMessageWithTime.split('1 second ago');
//                   textMessage =
//                       parts.first.trim(); // Take the first part (the message)
//
//                 }
//                 if (status == "api") {
//                   var message = messageData['message'];
//
//                   textMessage = message['message'];
//                   print(textMessage);
//
//                 }
//                 print(textMessage);
//                 // setState(() {
//                 typingTimer = Timer(const Duration(seconds: 2), () {
//                   chatBloc.add(ChatReadStatusEvent(
//                       userId: widget.id,
//                       roomId: widget.roomId,));
              // chatBloc.add(LoadRoomMessageEvent(
              //     page: 0, userId: widget.id, roomId: widget.roomId));
              // });
              // messagesList.insert(
              //   0,
              //   Message(
              //     body: textMessage, // Use the extracted text content
              //     toId: AppData.logInUserId,
              //     fromId: widget.id,
              //   ),
              // );
              // isLoading = false;
              // });
              // break;
              // Add more cases for other event types as needed
              default:
                // Handle unknown event types or ignore them
                break;
            }
          },
        );
        // clientSendChannel = await pusher.subscribe(
        //   channelName: "private-chatify.${widget.id}",
        //   onMemberAdded: (member) {
        //     // print("Member added: $member");
        //   },
        //   onMemberRemoved: (member) {
        //     // print("Member removed: $member");
        //   },
        //   onEvent: (event) {
        //     // print("Received Event (Listen Channel): $event");
        //   },
        // );

        // Attach an event listener to the channel
      } else {
        // Handle the case where Pusher connection failed
        // print("Failed to connect to Pusher");
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: svGetBgColor(),
      appBar: AppBar(
        surfaceTintColor: svGetScaffoldColor(),
        backgroundColor: svGetScaffoldColor(),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: svGetBodyColor(),size: 17,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          translation(context).lbl_chats,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/search.png',
              color: svGetBodyColor(),
              height: 20,
              width: 20,
            ),
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
      body: RefreshIndicator(
          onRefresh: _refresh,
          child: BlocConsumer<ChatBloc, ChatState>(
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
                return const UserShimmer();
              } else if (state is PaginationLoadedState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Observer(builder: (context){
                      return isCurrentlyOnNoInternet?Container(
                        padding: const EdgeInsets.all(10),
                          color: Colors.red,
                          child: Text(translation(context).msg_no_internet,style: TextStyle(color: Colors.white,fontSize: 14,fontFamily: 'Poppins',fontWeight: FontWeight.w500),)):SizedBox();},),
                    if (chatBloc.groupList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          translation(context).lbl_groups,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
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
                                  bloc.groupList.length -
                                      bloc.nextPageTrigger) {
                                bloc.add(
                                    CheckIfNeedMoreDataEvent(index: index));
                              }
                            }
                            if (bloc.numberOfPage != bloc.pageNumber - 1 &&
                                index >= bloc.groupList.length - 1) {
                              return const UserShimmer();
                            } else {
                              return GestureDetector(
                                onTap: () {
                                  ChatRoomScreen(
                                    username:
                                        bloc.groupList[index].groupName ?? '',
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
                                            translation(context).lbl_unknown,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: svGetBodyColor(),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        bloc.groupList[index].latestMessage ??
                                            '',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: svGetBodyColor(),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    // if (chatBloc.contactsList.isNotEmpty)
                    //   const Padding(
                    //     padding: EdgeInsets.all(16.0),
                    //     child: Text(
                    //       'Contacts',
                    //       style:
                    //           TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    //     ),
                    //   ),
                    if (chatBloc.contactsList.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: chatBloc.contactsList.length,
                          itemBuilder: (context, index) {
                            var bloc = chatBloc;
                            if (bloc.pageNumber <= bloc.numberOfPage) {
                              if (index ==
                                  bloc.contactsList.length -
                                      bloc.nextPageTrigger) {
                                bloc.add(
                                    CheckIfNeedMoreDataEvent(index: index));
                              }
                            }
                            if (bloc.numberOfPage != bloc.pageNumber - 1 &&
                                index >= bloc.contactsList.length - 1) {
                              return const UserShimmer();
                            } else {
                              return Container(
                                margin: const EdgeInsets.only(
                                    top: 8.0, left: 8.0, right: 8.0),
                                decoration: BoxDecoration(
                                    color: svGetScaffoldColor(),
                                    borderRadius: BorderRadius.circular(10)),
                                child: InkWell(
                                  onTap: () {
                                    bloc.contactsList[index].unreadCount = 0;
                                    setState(() {});
                                    ChatRoomScreen(
                                      username:
                                          '${bloc.contactsList[index].firstName ?? ''} ${bloc.contactsList[index].lastName ?? ''}',
                                      profilePic:
                                          '${bloc.contactsList[index].profilePic}',
                                      id: '${bloc.contactsList[index].id}',
                                      roomId:
                                          '${bloc.contactsList[index].roomId}',
                                    ).launch(context);
                                    // Add navigation logic or any other action on contact tap
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  SVProfileFragment(
                                                          userId: bloc
                                                              .contactsList[
                                                                  index]
                                                              .id)
                                                      .launch(context);
                                                },
                                                child: Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey
                                                            .withOpacity(0.3),
                                                        spreadRadius: 1,
                                                        blurRadius: 3,
                                                        offset:
                                                            const Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: CustomImageView(
                                                          placeHolder:
                                                              'images/socialv/faces/face_5.png',
                                                          imagePath:
                                                              '${AppData.imageUrl}${bloc.contactsList[index].profilePic ?? ''}',
                                                          height: 56,
                                                          width: 56,
                                                          fit: BoxFit.cover)
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
                                                              sanitizeString(
                                                                  "${bloc.contactsList[index].firstName ?? ""} ${bloc.contactsList[index].lastName ?? ''}"),
                                                              overflow:
                                                                  TextOverflow
                                                                      .clip,
                                                              style: TextStyle(
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  color:
                                                                      svGetBodyColor(),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      15))),
                                                      6.width,
                                                      // bloc.contactsList[index].isCurrentUser.validate()
                                                      //     ? Image.asset('images/socialv/icons/ic_TickSquare.png', height: 14, width: 14, fit: BoxFit.cover)
                                                      //     : const Offstage(),
                                                    ],
                                                  ),
                                                  (isSomeoneTyping &&
                                                          FromId ==
                                                              bloc
                                                                  .contactsList[
                                                                      index]
                                                                  .id)
                                                      ? Text(translation(context).lbl_typing,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Poppins',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                            color: Colors
                                                                .blueAccent,
                                                          ))
                                                      : Text(
                                                          (bloc
                                                                          .contactsList[
                                                                              index]
                                                                          .latestMessage
                                                                          ?.length ??
                                                                      0) >
                                                                  20
                                                              ? '${bloc.contactsList[index].latestMessage?.substring(0, 15)}....'
                                                              : bloc
                                                                      .contactsList[
                                                                          index]
                                                                      .latestMessage ??
                                                                  "",
                                                          style: secondaryTextStyle(
                                                              fontFamily:
                                                                  'Poppins',
                                                              color:
                                                                  svGetBodyColor())),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            if ((bloc.contactsList[index]
                                                        .unreadCount ??
                                                    0) >
                                                0)
                                              Container(
                                                height: 20,
                                                width: 20,
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  border: Border.all(
                                                    color: Colors.red,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${bloc.contactsList[index].unreadCount ?? 0}',
                                                    style: const TextStyle(
                                                      fontFamily:
                                                          'Poppins',
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            Text(
                                                timeAgo.format(DateTime.parse(
                                                    bloc.contactsList[index]
                                                            .latestMessageTime ??
                                                        '2024-01-01 00:00:00')),
                                                style: secondaryTextStyle(
                                                    fontFamily: 'Poppins',
                                                    color: svGetBodyColor(),
                                                    size: 12)),
                                          ],
                                        ),
                                        // isLoading ? const CircularProgressIndicator(color: svGetBodyColor(),):  AppButton(
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
                                        //       ? CircularProgressIndicator(color: svGetBodyColor(),) // Show progress indicator if loading
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
                              );
                            }
                          },
                        ),
                      )
                    else
                      Expanded(
                          child: Center(
                        child: Text(translation(context).msg_no_chats,
                            style: boldTextStyle(
                              size: 16,
                              fontFamily: 'Poppins',
                            )),
                      )),
                    if (AppData.isShowGoogleBannerAds ?? false)
                      BannerAdWidget(),
                  ],
                );
              } else if (state is DataError) {
                return RetryWidget(
                    errorMessage: translation(context).msg_chat_error,
                    onRetry: () {
                      try {
                        chatBloc.add(LoadPageEvent(page: 1));
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    });
              } else {
                return Center(child: Text(translation(context).msg_notification_error));
              }
            },
          )),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     GroupViewScreen().launch(context);
      //     // Add functionality to start a new chat
      //   },
      //   child: const Icon(Icons.group),
      // ),
    );
  }
}
